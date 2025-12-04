#!/usr/bin/env bash
set -euo pipefail

# create_policies.sh
# Run as admin. Creates four managed IAM policies using the JSON templates above.
#
# Usage:
#   AWS_PROFILE=your-admin-profile AWS_REGION=eu-west-1 ./create_policies.sh

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POL_DIR="${ROOT}/policies"

: "${AWS_PROFILE:?set AWS_PROFILE (admin)}"
: "${AWS_REGION:?set AWS_REGION}"
: "${PACKAGING_BUCKET:?set PACKAGING_BUCKET (unique)}"
: "${INPUT_BUCKET:?set INPUT_BUCKET (existing or to-be-created)}"

ACCOUNT=$(aws sts get-caller-identity --profile "${AWS_PROFILE}" --query Account --output text)

echo "Admin profile: ${AWS_PROFILE}"
echo "Region: ${AWS_REGION}"
echo "Account: ${ACCOUNT}"
echo "Packaging bucket: ${PACKAGING_BUCKET}"
echo "Input bucket: ${INPUT_BUCKET}"

# Helper: create or return existing policy ARN
create_policy() {
  local name="$1"
  local template="$2"
  local tmp="/tmp/${name}.json"
  echo "Processing policy ${name} from ${template}"
  # substitute placeholders
  ACCOUNT="${ACCOUNT}" REGION="${AWS_REGION}" PACKAGING_BUCKET="${PACKAGING_BUCKET}" INPUT_BUCKET="${INPUT_BUCKET}" envsubst < "${template}" > "${tmp}"

  # check if policy exists
  arn=$(aws iam list-policies --profile "${AWS_PROFILE}" --query "Policies[?PolicyName=='${name}'].Arn" --output text || true)
  if [ -n "${arn}" ]; then
    echo "Policy ${name} already exists: ${arn}"
    echo "${arn}"
    return 0
  fi

  out=$(aws iam create-policy --profile "${AWS_PROFILE}" --policy-name "${name}" --policy-document "file://${tmp}" 2>/dev/null || true)
  if [ -n "${out}" ]; then
    echo "${out}" | jq -r '.Policy.Arn'
  else
    # maybe created in another account call; fall back to list
    arn=$(aws iam list-policies --profile "${AWS_PROFILE}" --query "Policies[?PolicyName=='${name}'].Arn" --output text || true)
    echo "${arn}"
  fi
}

# create each
P1=$(create_policy "deploy-ci-cfn-project1" "${POL_DIR}/deploy-ci-cfn-project1.json")
P2=$(create_policy "deploy-ci-s3-packaging-input" "${POL_DIR}/deploy-ci-s3-packaging-input.json")
P3=$(create_policy "deploy-ci-lambda-deploy" "${POL_DIR}/deploy-ci-lambda-deploy.json")
P4=$(create_policy "deploy-ci-iam-passrole-logs" "${POL_DIR}/deploy-ci-iam-passrole-logs.json")

echo "Policies created/found:"
echo " P1: ${P1}"
echo " P2: ${P2}"
echo " P3: ${P3}"
echo " P4: ${P4}"

# save ARNs to file for later use
mkdir -p "${ROOT}/bootstrap"
cat > "${ROOT}/bootstrap/policy-arns.json" <<EOF
{
  "deploy-ci-cfn-project1": "${P1}",
  "deploy-ci-s3-packaging-input": "${P2}",
  "deploy-ci-lambda-deploy": "${P3}",
  "deploy-ci-iam-passrole-logs": "${P4}"
}
EOF

echo "Saved policy ARNs to ${ROOT}/bootstrap/policy-arns.json"
echo "Done."
