#!/usr/bin/env bash
set -euo pipefail

# Usage: ./attach-s3-notification.sh <INPUT_BUCKET> <LAMBDA_ARN> <ADMIN_PROFILE> <AWS_REGION>
INPUT_BUCKET=${1:-}
LAMBDA_ARN=${2:-}
ADMIN_PROFILE=${3:-admin-profile}
AWS_REGION=${4:-eu-west-1}

if [ -z "${INPUT_BUCKET}" ] || [ -z "${LAMBDA_ARN}" ]; then
  echo "Usage: $0 <INPUT_BUCKET> <LAMBDA_ARN> [ADMIN_PROFILE] [AWS_REGION]"
  exit 2
fi

cat > /tmp/s3-notification.json <<EOF
{
  "LambdaFunctionConfigurations": [
    {
      "Id": "DataQcLambdaCsvUpload",
      "LambdaFunctionArn": "${LAMBDA_ARN}",
      "Events": ["s3:ObjectCreated:*"],
      "Filter": {
        "Key": {
          "FilterRules": [
            {"Name": "suffix", "Value": ".csv"}
          ]
        }
      }
    }
  ]
}
EOF

echo "Adding lambda permission to allow S3 to invoke..."
aws lambda add-permission \
  --profile "${ADMIN_PROFILE}" \
  --function-name "${LAMBDA_ARN}" \
  --statement-id AllowS3InvokeLambda-$(date +%s) \
  --action "lambda:InvokeFunction" \
  --principal s3.amazonaws.com \
  --source-arn "arn:aws:s3:::${INPUT_BUCKET}" \
  --region "${AWS_REGION}" || true

echo "Putting bucket notification config..."
aws s3api put-bucket-notification-configuration \
  --profile "${ADMIN_PROFILE}" \
  --bucket "${INPUT_BUCKET}" \
  --notification-configuration file:///tmp/s3-notification.json \
  --region "${AWS_REGION}"

echo "Verification: "
aws s3api get-bucket-notification-configuration --bucket "${INPUT_BUCKET}" --profile "${ADMIN_PROFILE}" --region "${AWS_REGION}" | jq .

echo "Done."
