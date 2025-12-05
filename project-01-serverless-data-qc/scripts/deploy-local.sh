#!/usr/bin/env bash
set -euo pipefail
# run from project-01-serverless-data-qc
DEPLOY_PROFILE=${DEPLOY_PROFILE:-deploy-ci}
AWS_REGION=${AWS_REGION:-eu-west-1}
PACKAGING_BUCKET=${PACKAGING_BUCKET:-cmogbo-sam-pkg-1764511935}
INPUT_BUCKET=${INPUT_BUCKET:-508012525512-data-qc-input}

echo "Activating venv if present..."
[ -f .venv/bin/activate ] && source .venv/bin/activate || true

echo "Building..."
sam build

echo "Deploying (profile=${DEPLOY_PROFILE})..."
sam deploy \
  --profile "${DEPLOY_PROFILE}" \
  --stack-name project1-data-qc \
  --s3-bucket "${PACKAGING_BUCKET}" \
  --parameter-overrides InputBucketName="${INPUT_BUCKET}" \
  --region "${AWS_REGION}" \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --no-confirm-changeset \
  --no-fail-on-empty-changeset

echo "If S3 notification configuration failed due to permission errors, ask admin to run infra/bootstrap/attach-s3-notification.sh"
