# Project 01 — Serverless Data Quality Pipeline (S3 → Lambda → QC Report)

## Summary
A lightweight, production-like serverless pipeline that validates CSV uploads to S3, generates a QC report (JSON), and writes the report back to S3. Demonstrates serverless design, testable validation logic, and least-privilege cloud deployment.

## Business problem
Uploading inconsistent CSVs breaks downstream analytics. This pipeline automates checks and emits a structured QC report so analysts get clean inputs and engineering can triage issues.

## Objectives (MVP)
- Validate CSV schema (required columns, types).
- Detect nulls, out-of-range ages, invalid dates.
- Produce human + machine-readable QC JSON and store in S3.
- Local dev: run validations locally and simulate S3 event.
- Deployment: SAM template to deploy Lambda + S3 trigger with least-privilege IAM.

## What this demonstrates
- Serverless ETL fundamentals (event-driven S3 → Lambda).
- Testable validator functions.
- Infrastructure-as-code (SAM/CloudFormation).
- Dev workflow: atomic commits, CI-friendly tests, diagram-first design.

## Folder layout
project-01-serverless-data-qc/
├── src/
│ ├── handler.py
│ ├── validator.py
│ └── utils.py
├── tests/
│ └── test_validator.py
├── samples/
│ ├── good.csv
│ └── bad_missing.csv
├── requirements.txt
├── template.yaml
├── iam_policy.json
├── diagrams/
│ └── architecture.drawio
└── scripts/
└── local_invoke.py


## Quick dev steps (local)
1. Create virtualenv & install deps:
\`\`\`bash
#!/bin/bash
python -m venv .venv`
source .venv/bin/activate
pip install -r requirements.txt
\`\`\`

2. Run tests:
\`\`\`bash
#!/bin/bash
pytest -q
\`\`\`

3. Simulate S3 event locally:
\`\`\`bash
#!/bin/bash
python scripts/local_invoke.py samples/good.csv
\`\`\`

4. Deploy with AWS SAM (optional):
\`\`\`bash
sam build
sam deploy --guided
\`\`\`


## Next improvements
- Add JSON Schema-based ruleset for validation config.
- Add Athena integration for aggregated QC metrics.
- Add SNS alerting for critical failures.
