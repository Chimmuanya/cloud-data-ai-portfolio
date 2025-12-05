#!/usr/bin/env bash
set -euo pipefail

# Usage: sudo-admin-run: ./create-deploy-ci.sh <ACCOUNT_ID> <AWS_REGION> <PACKAGING_BUCKET> <INPUT_BUCKET>
ACCOUNT_ID=${1:-}
AWS_REGION=${2:-eu-west-1}
PACKAGING_BUCKET=${3:-}
INPUT_BUCKET=${4:-}
ADMIN_PROFILE=${ADMIN_PROFILE:-admin-profile}
NEW_USER=${NEW_USER:-deploy-ci}
GROUP=${GROUP:-deploy-ci-group}

if [ -z "$ACCOUNT_ID" ]; then
  echo "Usage: $0 <ACCOUNT_ID> <AWS_REGION> <PACKAGING_BUCKET> <INPUT_BUCKET>"
  exit 2
fi

echo "Creating group ${GROUP} and user ${NEW_USER} and attaching managed policies..."
aws iam create-group --group-name "${GROUP}" --profile "${ADMIN_PROFILE}" 2>/dev/null || true
aws iam create-user --user-name "${NEW_USER}" --profile "${ADMIN_PROFILE}" 2>/dev/null || true
aws iam add-user-to-group --group-name "${GROUP}" --user-name "${NEW_USER}" --profile "${ADMIN_PROFILE}" || true

# Create managed policies from infra/policies (idempotent)
for p in deploy-ci-cfn-scoped-policy deploy-ci-s3-packaging-policy deploy-ci-lambda-iam-policy deploy-ci-cloudwatch-policy; do
  jqfile="infra/policies/${p}.json"
  if [ ! -f "${jqfile}" ]; then
    echo "Missing ${jqfile}"
    exit 3
  fi
  # try to create, else get existing ARN
  if arn=$(aws iam create-policy --policy-name "${p}" --policy-document "file://${jqfile}" --profile "${ADMIN_PROFILE}" 2>/dev/null | jq -r .Policy.Arn 2>/dev/null); then
    echo "Created ${p} => ${arn}"
  else
    arn=$(aws iam list-policies --scope Local --profile "${ADMIN_PROFILE}" --query "Policies[?PolicyName=='${p}'].Arn | [0]" --output text)
    echo "Found existing ${p} => ${arn}"
  fi

  aws iam attach-group-policy --group-name "${GROUP}" --policy-arn "${arn}" --profile "${ADMIN_PROFILE}" || true
done

# Optionally create packaging bucket if doesn't exist (admin)
if ! aws s3api head-bucket --bucket "${PACKAGING_BUCKET}" --profile "${ADMIN_PROFILE}" >/dev/null 2>&1; then
  echo "Creating packaging bucket: ${PACKAGING_BUCKET}"
  aws s3api create-bucket --bucket "${PACKAGING_BUCKET}" --create-bucket-configuration LocationConstraint="${AWS_REGION}" --region "${AWS_REGION}" --profile "${ADMIN_PROFILE}"
fi

echo "Create access keys for ${NEW_USER} (store securely) ..."
aws iam create-access-key --user-name "${NEW_USER}" --profile "${ADMIN_PROFILE}" | jq '.AccessKey | {AccessKeyId:.AccessKeyId, SecretAccessKey:.SecretAccessKey}'

echo "Done. Please add credentials to CI secrets or your local ~/.aws/credentials under profile 'deploy-ci'."
