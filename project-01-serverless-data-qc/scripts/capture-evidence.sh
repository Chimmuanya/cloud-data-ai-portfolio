#!/usr/bin/env bash
# project-01-serverless-data-qc/scripts/capture-evidence.sh
# Purpose: Collect evidence (S3 reports, CloudWatch logs, CloudFormation, Lambda & notifications)
# Merges user's positional-arg interface with robust collection, manifest, and tarballing.
# Atomic commit message: chore(evidence): replace capture-evidence.sh with hardened positional-args version
set -euo pipefail

# -------------------------
# Usage / defaults (positional)
# -------------------------
USAGE=$(cat <<'EOF'
Usage: capture-evidence.sh [PROFILE] [AWS_REGION] [STACK_NAME] [INPUT_BUCKET] [LAMBDA_NAME]
Arguments are optional. Default values shown in braces {}.

Example 1 (Using defaults): ./capture-evidence.sh
Example 2 (Specifying profile and region): ./capture-evidence.sh deploy-ci-prod us-east-1

Parameters:
  1: PROFILE       AWS CLI Profile to use. {deploy-ci}
  2: AWS_REGION    AWS region where the stack is deployed. {eu-west-1}
  3: STACK_NAME    Name of the CloudFormation stack. {project1-data-qc}
  4: INPUT_BUCKET  Name of the S3 bucket holding input data/reports. {508012525512-data-qc-input}
  5: LAMBDA_NAME   Name of the deployed Lambda function. {data-qc-lambda-project1-data-qc}
Notes:
  - This script will create a timestamped folder under project-01-serverless-data-qc/evidence/
  - If environment variable EVIDENCE_S3 is set, the resulting tarball will be uploaded to that S3 bucket.
  - Adjust MAX_REPORTS below if you want more/fewer QC JSON downloads.
EOF
)

# Default values (match your original defaults)
PROFILE="${1:-deploy-ci}"
AWS_REGION="${2:-eu-west-1}"
STACK_NAME="${3:-project1-data-qc}"
INPUT_BUCKET="${4:-}"
LAMBDA_NAME="${5:-data-qc-lambda-${STACK_NAME}}"

# Tunables
MAX_REPORTS="${MAX_REPORTS:-15}"   # can override via env var
OUT_DIR_BASE="project-01-serverless-data-qc/evidence"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="${OUT_DIR_BASE}/${TIMESTAMP}"
mkdir -p "${OUT_DIR}"

echo "capture-evidence.sh"
echo "Profile: ${PROFILE}"
echo "Region:  ${AWS_REGION}"
echo "Stack:   ${STACK_NAME}"
echo "Input:   ${INPUT_BUCKET}"
echo "Lambda:  ${LAMBDA_NAME}"
echo "Output:  ${OUT_DIR}"
echo "Max QC files: ${MAX_REPORTS}"
if [ -n "${EVIDENCE_S3:-}" ]; then
  echo "Will upload tarball to S3: ${EVIDENCE_S3}"
fi
echo "--------------------------------------------------------"

# Check required commands
for cmd in aws jq tar date basename mkdir; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "ERROR: required command '${cmd}' not found. Install it and retry."
    exit 2
  fi
done

# Helper to run aws calls with profile & region (captures stderr to .err file when provided)
aws_run() {
  # usage: aws_run <errfile> <aws-args...>
  local errfile="$1"; shift
  if ! aws --profile "${PROFILE}" --region "${AWS_REGION}" "$@" > "${OUT_DIR}/$(basename "${errfile}.out")" 2> "${OUT_DIR}/${errfile}.err"; then
    echo "WARN: aws call failed (see ${OUT_DIR}/${errfile}.err) -- continuing"
    return 1
  fi
  return 0
}

# 1) CloudFormation describe-stacks (keep original filename)
echo "1) Saving CloudFormation describe-stacks..."
if ! aws --profile "${PROFILE}" --region "${AWS_REGION}" cloudformation describe-stacks --stack-name "${STACK_NAME}" > "${OUT_DIR}/cloudformation-describe.json" 2> "${OUT_DIR}/cloudformation-describe.err"; then
  echo "WARN: describe-stacks failed (see cloudformation-describe.err)"
fi

# 2) Listing & downloading reports from s3://<INPUT_BUCKET>/reports/
echo "2) Listing reports in s3://${INPUT_BUCKET}/reports/ and downloading up to ${MAX_REPORTS} JSON(s)..."
REPORT_KEYS=$(aws --profile "${PROFILE}" --region "${AWS_REGION}" s3api list-objects-v2 --bucket "${INPUT_BUCKET}" --prefix "reports/" --query "sort_by(Contents,&LastModified)[-${MAX_REPORTS}:].Key" --output text 2> "${OUT_DIR}/list-reports.err" || true)

if [ -n "${REPORT_KEYS}" ]; then
  for key in ${REPORT_KEYS}; do
    file=$(basename "${key}")
    echo " - Downloading ${key} -> ${OUT_DIR}/${file}"
    if ! aws --profile "${PROFILE}" --region "${AWS_REGION}" s3 cp "s3://${INPUT_BUCKET}/${key}" "${OUT_DIR}/${file}" 2> "${OUT_DIR}/fetch-${file}.err"; then
      echo "   WARN: failed to download ${key} (see fetch-${file}.err)"
    fi
  done
else
  echo "No reports found under reports/ (ensure tests ran and files exist)."
fi

# 3) CloudWatch logs (your original tail + describe)
echo "3) Capturing recent CloudWatch logs for Lambda function ${LAMBDA_NAME}..."
LOG_GROUP="/aws/lambda/${LAMBDA_NAME}"
if ! aws --profile "${PROFILE}" --region "${AWS_REGION}" logs describe-log-streams --log-group-name "${LOG_GROUP}" --order-by LastEventTime --descending --max-items 5 > "${OUT_DIR}/log-streams.json" 2> "${OUT_DIR}/log-streams.err"; then
  echo "WARN: describe-log-streams failed (see log-streams.err)"
fi

# prefer 'aws logs tail' when available; fallback gracefully
if aws --profile "${PROFILE}" --region "${AWS_REGION}" logs help >/dev/null 2>&1; then
  # 'aws logs tail' supports --since; keep your default 1h recent tail (non-fatal)
  if ! aws --profile "${PROFILE}" --region "${AWS_REGION}" logs tail "${LOG_GROUP}" --since 1h > "${OUT_DIR}/cloudwatch_tail_last1h.txt" 2> "${OUT_DIR}/cloudwatch_tail.err"; then
    echo "WARN: logs tail failed (see cloudwatch_tail.err)"
  fi
else
  echo "INFO: 'aws logs tail' not available; attempting get-log-events from latest stream if present."
  LATEST_STREAM="$(jq -r '.logStreams[0].logStreamName // empty' "${OUT_DIR}/log-streams.json" 2>/dev/null || echo "")"
  if [ -n "${LATEST_STREAM}" ]; then
    if ! aws --profile "${PROFILE}" --region "${AWS_REGION}" logs get-log-events --log-group-name "${LOG_GROUP}" --log-stream-name "${LATEST_STREAM}" --limit 10000 > "${OUT_DIR}/cloudwatch_latest_stream.json" 2> "${OUT_DIR}/cloudwatch_get.err"; then
      echo "WARN: get-log-events failed (see cloudwatch_get.err)"
    fi
  else
    echo "No CloudWatch streams found for ${LOG_GROUP}"
  fi
fi

# 4) Save S3 bucket notification configuration (may require admin)
echo "4) Saving S3 bucket notification configuration for ${INPUT_BUCKET}..."
if ! aws --profile "${PROFILE}" --region "${AWS_REGION}" s3api get-bucket-notification-configuration --bucket "${INPUT_BUCKET}" > "${OUT_DIR}/bucket-notification-config.json" 2> "${OUT_DIR}/bucket-notification-config.err"; then
  echo "WARN: get-bucket-notification-configuration failed (see bucket-notification-config.err). You may need admin rights."
fi

# 5) Additional helpful items: lambda config, role, attached policies (best-effort)
echo "5) Getting Lambda configuration and role info (best-effort)..."
if ! aws --profile "${PROFILE}" --region "${AWS_REGION}" lambda get-function-configuration --function-name "${LAMBDA_NAME}" > "${OUT_DIR}/lambda_config.json" 2> "${OUT_DIR}/lambda_config.err"; then
  echo "WARN: lambda get-function-configuration failed (see lambda_config.err)"
else
  ROLE_ARN="$(jq -r '.Role // empty' "${OUT_DIR}/lambda_config.json" 2>/dev/null || echo "")"
  if [ -n "${ROLE_ARN}" ]; then
    ROLE_NAME="$(basename "${ROLE_ARN}")"
    if ! aws --profile "${PROFILE}" --region "${AWS_REGION}" iam get-role --role-name "${ROLE_NAME}" > "${OUT_DIR}/lambda_role.json" 2> "${OUT_DIR}/lambda_role.err"; then
      echo "WARN: iam get-role failed (see lambda_role.err)"
    fi
    if ! aws --profile "${PROFILE}" --region "${AWS_REGION}" iam list-attached-role-policies --role-name "${ROLE_NAME}" > "${OUT_DIR}/lambda_attached_policies.json" 2> "${OUT_DIR}/lambda_attached_policies.err"; then
      echo "WARN: list-attached-role-policies failed (see lambda_attached_policies.err)"
    fi
  fi
fi

# 6) Optional: list-stack-resources
echo "6) Listing CloudFormation stack resources (best-effort)..."
if ! aws --profile "${PROFILE}" --region "${AWS_REGION}" cloudformation list-stack-resources --stack-name "${STACK_NAME}" > "${OUT_DIR}/cf_resources.json" 2> "${OUT_DIR}/cf_resources.err"; then
  echo "WARN: list-stack-resources failed (see cf_resources.err)"
fi

# 7) Small IAM audit (non-sensitive)
echo "7) Capturing IAM users list (non-sensitive)..."
if ! aws --profile "${PROFILE}" --region "${AWS_REGION}" iam list-users > "${OUT_DIR}/iam_list_users.json" 2> "${OUT_DIR}/iam_list_users.err"; then
  echo "WARN: iam list-users failed (see iam_list_users.err)"
fi

# 8) Manifest
echo "8) Writing manifest..."
cat > "${OUT_DIR}/manifest.json" <<EOF
{
  "timestamp": "${TIMESTAMP}",
  "profile": "${PROFILE}",
  "region": "${AWS_REGION}",
  "stack_name": "${STACK_NAME}",
  "input_bucket": "${INPUT_BUCKET}",
  "lambda_name": "${LAMBDA_NAME}",
  "max_reports": ${MAX_REPORTS}
}
EOF

# 9) Tarball evidence folder
TARBALL="${OUT_DIR}.tar.gz"
echo "9) Creating tarball ${TARBALL}..."
tar -czf "${TARBALL}" -C "$(dirname "${OUT_DIR}")" "$(basename "${OUT_DIR}")"

# 10) Optionally upload tarball if EVIDENCE_S3 env var set (keeps API consistent; admin must ensure bucket exists)
if [ -n "${EVIDENCE_S3:-}" ]; then
  echo "10) Uploading tarball to s3://${EVIDENCE_S3}/"
  if ! aws --profile "${PROFILE}" --region "${AWS_REGION}" s3 cp "${TARBALL}" "s3://${EVIDENCE_S3}/" > /dev/null 2> "${OUT_DIR}/upload-evidence.err"; then
    echo "WARN: upload to s3://${EVIDENCE_S3} failed (see ${OUT_DIR}/upload-evidence.err)"
  else
    echo "Uploaded ${TARBALL} to s3://${EVIDENCE_S3}/"
  fi
fi

echo "All evidence saved to: ${OUT_DIR}"
echo "Tarball: ${TARBALL}"
echo "Done."
