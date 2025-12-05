#!/usr/bin/env bash
# infra/bootstrap/envsubst-wrap.sh
# Usage: infra/bootstrap/envsubst-wrap.sh <ACCOUNT_ID> <AWS_REGION> <PACKAGING_BUCKET> <INPUT_BUCKET>
set -euo pipefail

ACCOUNT_ID="${1:-}"
AWS_REGION="${2:-eu-west-1}"
PACKAGING_BUCKET="${3:-}"
INPUT_BUCKET="${4:-}"

mkdir -p infra/policies/generated
for f in infra/policies/*.json; do
  base=$(basename "$f")
  echo "Rendering $f -> infra/policies/generated/$base"
  ACCOUNT_ID="${ACCOUNT_ID}" AWS_REGION="${AWS_REGION}" PACKAGING_BUCKET="${PACKAGING_BUCKET}" INPUT_BUCKET="${INPUT_BUCKET}" envsubst < "$f" > "infra/policies/generated/$base"
done

echo "Rendered templates in infra/policies/generated/"
