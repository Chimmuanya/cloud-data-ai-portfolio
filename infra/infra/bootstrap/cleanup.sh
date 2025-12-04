#!/usr/bin/env bash
set -euo pipefail

# create_role_and_attach.sh
# Create OIDC-assumable role for GitHub Actions and attach managed policies created earlier.
#
# Usage:
#   AWS_PROFILE=your-admin-profile AWS_REGION=eu-west-1 REPO_SLUG=org/repo ./create_role_and_attach.sh

: "${AWS_PROFILE:?set AWS_PROFILE (admin)}"
: "${AWS_REGION:?set AWS_REGION}"
: "${REPO_SLUG:?set REPO_SLUG (e.g. cmogbo/cloud-data-ai-portfolio)}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POL_ARNS_FILE="${ROOT}/bootstrap/policy-arns.json"

if [ ! -f "${POL_ARNS_FILE}" ]; then
  echo "Policy ARNs file not found: ${POL_ARNS_FILE}. Run create_policies.sh first."
  exit 1
fi

ACCOUNT=$(aws sts get-caller-identity --profile "${AWS_PROFILE}" --query Account --output text)
OIDC_PROVIDER_ARN="arn:aws:iam::${ACCOUNT}:oidc-provider/token.actions.githubusercontent.com"
ROLE_NAME="ci-deploy-project1-role"

echo "Admin profile: ${AWS_PROFILE}"
echo "Region: ${AWS_REGION}"
echo "Account: ${ACCOUNT}"
echo "Repo slug (allowed): ${REPO_SLUG}"
echo "OIDC provider: ${OIDC_PROVIDER_ARN}"

# Create trust policy (scoped to main branch)
cat > /tmp/trust-policy-${ROLE_NAME}.json <<EOF
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Effect":"Allow",
      "Principal": { "Federated": "${OIDC_PROVIDER_ARN}" },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition":{
        "StringLike":{
          "token.actions.githubusercontent.com:sub":"repo:${REPO_SLUG}:ref:refs/heads/main"
        }
      }
    }
  ]
}
EOF

# create role if not exists
if aws iam get-role --role-name "${ROLE_NAME}" --profile "${AWS_PROFILE}" >/dev/null 2>&1; then
  echo "Role ${ROLE_NAME} already exists."
else
  echo "Creating role ${ROLE_NAME}"
  aws iam create-role --role-name "${ROLE_NAME}" --assume-role-policy-document file:///tmp/trust-policy-${ROLE_NAME}.json --description "CI deploy role for project1 (SAM deploy)" --profile "${AWS_PROFILE}"
fi

# attach policies
P1=$(jq -r '.["deploy-ci-cfn-project1"]' "${POL_ARNS_FILE}")
P2=$(jq -r '.["deploy-ci-s3-packaging-input"]' "${POL_ARNS_FILE}")
P3=$(jq -r '.["deploy-ci-lambda-deploy"]' "${POL_ARNS_FILE}")
P4=$(jq -r '.["deploy-ci-iam-passrole-logs"]' "${POL_ARNS_FILE}")

for p in "${P1}" "${P2}" "${P3}" "${P4}"; do
  echo "Attaching ${p} to ${ROLE_NAME}"
  aws iam attach-role-policy --role-name "${ROLE_NAME}" --policy-arn "${p}" --profile "${AWS_PROFILE}"
done

echo "Role ARN:"
aws iam get-role --role-name "${ROLE_NAME}" --profile "${AWS_PROFILE}" --query 'Role.Arn' --output text

echo "Done. Role ${ROLE_NAME} created/ensured and policies attached."
