#!/usr/bin/env bash
set -euo pipefail

ACCOUNT_ID="508012525512"
ROLE_NAME="ci-deploy-project1-role"

aws iam create-role \
  --role-name "${ROLE_NAME}" \
  --assume-role-policy-document file://policies/ci-deploy-assume-role-trust.json

aws iam put-role-policy \
  --role-name "${ROLE_NAME}" \
  --policy-name ci-deploy-project1-policy \
  --policy-document file://policies/ci-deploy-policy.json

echo "Created role arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
