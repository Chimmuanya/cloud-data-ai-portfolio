#!/usr/bin/env bash
# project-01-serverless-data-qc/scripts/generate-samconfig.sh

# Usage: project-01-serverless-data-qc/scripts/generate-samconfig.sh PROFILE AWS_REGION PACKAGING_BUCKET INPUT_BUCKET
set -euo pipefail

PROFILE="${1:-}"
AWS_REGION="${2:-}"
PACKAGING_BUCKET="${3:-}"
INPUT_BUCKET="${4:-}"

cat > project-01-serverless-data-qc/samconfig.toml <<EOF
version = 0.1

[default.deploy]
profile = "${PROFILE}"
region = "${AWS_REGION}"
stack_name = "project1-data-qc"
s3_bucket = "${PACKAGING_BUCKET}"
s3_prefix = "project1-data-qc"
capabilities = "CAPABILITY_IAM CAPABILITY_NAMED_IAM"
parameter_overrides = "InputBucketName=${INPUT_BUCKET}"
EOF

echo "Wrote project-01-serverless-data-qc/samconfig.toml"
