# 🚀 Serverless Data Quality Pipeline

[![AWS](https://img.shields.io/badge/AWS-Lambda%20%7C%20S3-FF9900?style=flat&logo=amazon-aws)](https://aws.amazon.com/)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=flat&logo=python&logoColor=white)](https://www.python.org/)
[![SAM](https://img.shields.io/badge/AWS-SAM-orange?style=flat)](https://aws.amazon.com/serverless/sam/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> A production-grade, event-driven data quality validation pipeline built with AWS serverless technologies. Automatically validates CSV files on upload and generates comprehensive quality reports. **Engineered to mirror real-world enterprise constraints, IAM complexity, and operational requirements.**

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Architecture](#-architecture)
- [Production Engineering Story](#-production-engineering-story)
- [Quick Start](#-quick-start)
- [Deployment Guide](#-deployment-guide)
- [Project Structure](#-project-structure)
- [IAM & Security](#-iam--security)
- [Testing & Validation](#-testing--validation)
- [Troubleshooting](#-troubleshooting)
- [Roadmap](#-roadmap)
- [What This Project Demonstrates](#-what-this-project-demonstrates)

---

## Overview

This project implements a **fully automated, serverless data quality pipeline** that validates CSV files in real-time as they're uploaded to S3. Built with AWS SAM (Serverless Application Model), it demonstrates production-grade cloud engineering practices, comprehensive IAM security design, and automated data validation workflows.

### How It Works

```
📁 CSV Upload → 🪣 S3 Bucket → ⚡ Lambda Trigger → 🔍 Data Validation → 📊 Quality Report
```

1. **Upload**: CSV file lands in `s3://<account-id>-data-qc-input/`
2. **Trigger**: S3 event automatically invokes Lambda function
3. **Validate**: Lambda performs schema validation, missing field checks, and data quality analysis
4. **Report**: JSON quality report saved to `s3://<account-id>-data-qc-input/reports/`

### Use Cases

- **Data Lake Ingestion**: Validate incoming data before processing to prevent downstream pipeline failures
- **ETL Quality Gates**: Automated quality checks ensuring only validated data enters analytics systems
- **Healthcare/Life Sciences**: Data integrity validation for regulatory compliance (HIPAA, FDA)
- **Operational Monitoring**: Continuous data quality assessment with automated alerting
- **Cost-Effective Validation**: Serverless architecture with pay-per-use pricing (no idle infrastructure costs)

---

## Key Features

| Feature | Description |
|---------|-------------|
| **Zero Infrastructure** | Fully serverless - no servers to manage or maintain |
| **Event-Driven** | Automatic triggering via S3 events - zero-latency validation |
| **Security First** | Least-privilege IAM model with scoped policies and role separation |
| **Modular Design** | Reusable validation engine with clean separation of concerns |
| **CI/CD Ready** | GitHub Actions workflow with OIDC authentication |
| **Comprehensive Reports** | Detailed JSON quality reports with actionable insights |
| **Scalable** | Handles concurrent file uploads automatically via Lambda scaling |
| **Cost-Efficient** | Pay only for execution time - typical validation costs < $0.01 per file |
| **IaC-Driven** | 100% infrastructure-as-code using AWS SAM/CloudFormation |
| **Production-Ready** | Observability, error handling, and operational best practices built-in |

---

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     S3 Input Bucket                              │
│              s3://<account-id>-data-qc-input/                    │
│                                                                   │
│  📄 vendor_data.csv uploaded (manual or automated)               │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ S3 Event Notification
                         │ (ObjectCreated:Put)
                         │ Suffix Filter: *.csv
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Lambda Function                               │
│                   data-qc-lambda                                 │
│                   Runtime: Python 3.10                           │
│                                                                   │
│  ┌──────────────────────────────────────────────────┐           │
│  │  handler.py                                       │           │
│  │  • Receives S3 event payload                      │           │
│  │  • Downloads CSV from S3                          │           │
│  │                                                    │           │
│  │  validator.py                                     │           │
│  │  • Parse CSV with pandas                          │           │
│  │  • Validate schema and data types                 │           │
│  │  • Check for missing/null values                  │           │
│  │  • Apply business rule validations                │           │
│  │  • Generate quality metrics & statistics          │           │
│  │                                                    │           │
│  │  utils.py                                         │           │
│  │  • S3 helpers, logging, error formatting          │           │
│  └──────────────────────────────────────────────────┘           │
│                                                                   │
│  CloudWatch Logs: Execution logs, errors, metrics                │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ PutObject (validation report)
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                  S3 Reports Prefix                               │
│         s3://<account-id>-data-qc-input/reports/                 │
│                                                                   │
│  📊 vendor_data.csv.json                                         │
│     {                                                            │
│       "file": "vendor_data.csv",                                 │
│       "status": "PASS" | "FAIL",                                 │
│       "validations": [...],                                      │
│       "errors": [...],                                           │
│       "metadata": {...}                                          │
│     }                                                            │
└─────────────────────────────────────────────────────────────────┘
```

### Technology Stack

- **Compute**: AWS Lambda (Python 3.10+)
- **Storage**: Amazon S3 (input + reports)
- **Event Routing**: S3 Event Notifications
- **IaC**: AWS SAM (Serverless Application Model) / CloudFormation
- **CI/CD**: GitHub Actions with OIDC
- **Language**: Python 3.10+
- **Libraries**: pandas, boto3, pytest
- **Monitoring**: Amazon CloudWatch Logs

---

## Production Engineering Story

### **How This System Would Run in a Real Company**

This project was **engineered to simulate real enterprise data platform constraints**, not just to process CSV files. Rather than building the simplest possible solution, It was designed around the operational realities of production systems: **automation, auditability, IAM least-privilege, reproducibility, and clear observability**.

---

### **1. The Real-World Problem Being Solved**

Teams frequently ingest external CSV data into data lakes using workflows like:

```
S3 → AWS Glue ETL → Amazon Redshift/Snowflake → Dashboards
```

**The problem:** Bad or malformed CSV files commonly break downstream jobs, causing:

- Pipeline failures requiring manual intervention
- Delayed reports affecting business decisions
- Corrupted datasets requiring expensive reprocessing
- Lost trust in data quality
- Engineering time wasted on reactive debugging

**The solution:** This pipeline introduces **automated pre-ingestion validation**, acting as a quality gate that ensures only validated data enters the lake. It's the same pattern used by companies like Netflix, Airbnb, and Uber in their data platforms.

---

### **2. Why Event-Driven S3 → Lambda Architecture**

S3 event notifications trigger Lambda **immediately** when a file is uploaded, enabling:

**Zero-latency validation** - Files are checked within milliseconds of upload  
**Pay-per-use compute** - No idle servers or wasted capacity  
**Automated QC without user intervention** - Validation happens automatically  
**Low operational overhead** - No servers to patch, scale, or monitor  
**Natural backpressure handling** - Lambda scales automatically with load  

This is the **same architectural pattern** used in production AWS data ingestion pipelines at companies processing billions of events daily.

---

### **3. Infrastructure-as-Code as a Production Requirement**

The system is defined using **AWS SAM (Serverless Application Model)**, which compiles to CloudFormation, guaranteeing:

**Identical deployments across environments** (dev/staging/prod)  
**Versioned, testable infrastructure** tracked in Git  
**Rollbacks and change auditing** via CloudFormation change sets  
**Reproducible onboarding** for new engineers (no tribal knowledge)  
**Peer review of infrastructure changes** via pull requests  

**Why this matters in real companies:**

In enterprise environments, manual console deployments lead to:
- Configuration drift between environments
- "It works on my account" syndrome
- Inability to reproduce production issues locally
- No audit trail for compliance (SOC 2, ISO 27001)

---

### **4. IAM Least-Privilege: The Hardest and Most Important Part**

Simulating production IAM is one of the **hardest real-world cloud engineering challenges**.

#### **The Lambda Execution Role**

The Lambda function requires **only** the minimal permissions needed:

```json
{
  "Effect": "Allow",
  "Action": [
    "s3:GetObject",
    "s3:PutObject"
  ],
  "Resource": [
    "arn:aws:s3:::<account-id>-data-qc-input/*"
  ]
}
```

**Why this matters:** In a production breach scenario, a compromised Lambda can't:
- Delete S3 objects
- Access other buckets
- Modify IAM policies
- Escalate privileges

#### **The Deployment User (deploy-ci)**

During development, I encountered multiple IAM failures that reflect **real production challenges**:

❌ **`AccessDenied` on `iam:CreateRole`** - CloudFormation needs to create Lambda execution roles  
❌ **`AccessDenied` on `iam:TagRole`** - CFN requires tagging permissions for every resource  
❌ **`AccessDenied` on `s3:PutBucketNotification`** - S3 event configuration requires special permissions  
❌ **Circular dependency errors** - Roles, policies, and Lambda functions have ordering constraints  
❌ **CloudFormation rollback failures** - Incomplete IAM permissions cause stuck stacks  

**The solution:** Four separate, scoped IAM policies of same names or names similar to these:

1. **`deploy-ci-s3-packaging.json`** - S3 operations for deployment artifacts
2. **`deploy-ci-cfn-mgmt.json`** - CloudFormation stack lifecycle (scoped to `project1-data-qc`)
3. **`deploy-ci-lambda-mgmt.json`** - Lambda function creation/updates
4. **`deploy-ci-iam-passrole.json`** - PassRole permission (scoped to project-specific roles only)

**Key lessons learned:**

- Scope IAM roles to **only the resources they manage** using specific ARNs
- CloudFormation requires `iam:TagRole` for resource tracking (non-obvious requirement)
- Separate **deployment users** from **administrators** (role separation)
- Document IAM flows to avoid **tribal knowledge** and onboarding friction

---

### **5. S3 Event Notification Complexity (A Real Production Constraint)**

A **production constraint** I encountered:

**AWS doesn't allow CloudFormation-created Lambdas to modify bucket notifications** unless the bucket itself is also managed by CloudFormation. This prevents accidental overwriting of existing event configurations.

**The problem:**

```
Existing S3 Bucket → Want to add Lambda trigger via CloudFormation
CloudFormation refuses: "Cannot modify bucket notifications on unmanaged bucket"
```

**The solution:**

I implemented a **hybrid approach** that mirrors real enterprise scenarios:

1. CloudFormation deploys the Lambda function and IAM roles
2. A separate admin script (`attach-s3-notifications.sh`) configures the S3 event
3. Documentation clearly separates the two steps

---

### **6. CI/CD as a Production System Contract**

A GitHub Actions pipeline builds and deploys the application consistently using (Not yet tested by me as at the time of deployment):

**OpenID Connect (OIDC) → IAM Role assumption** (no long-lived credentials)  
**Dedicated deployment user** (`deploy-ci`) with scoped permissions  
**Automated `sam build` + `sam deploy`** steps  
**Change set preview** before production deployment  
**Rollback capability** via CloudFormation versioning  

**Potential benefits:**

- No manual deployments → eliminates human error
- Consistent builds → prevents "works on my machine" issues
- Audit trail → every deployment is tracked in Git history
- Security → OIDC tokens expire, no credentials in CI/CD logs

---

### **7. Operational Awareness Built Into the Design**

#### **Observability**

- **CloudWatch Logs** for monitoring validation failures
- **Structured logging** with timestamps and request IDs
- **Error categorization** (schema errors vs. data errors vs. system errors)

#### **Data Organization**

- **Separate prefixes** for input files vs. reports (`reports/`)
- **Account-scoped bucket naming** (`<account-id>-data-qc-input`) prevents collisions
- **Timestamped reports** for historical tracking

#### **Error Handling**

- **Graceful failure** - Lambda logs errors but doesn't crash
- **Partial validation** - Generates reports even for incomplete files
- **Clear error messages** - Actionable feedback for data providers

**Other features that could be added:**

- Dead Letter Queue (DLQ) for failed Lambda invocations
- CloudWatch Alarms for validation failure rates
- SNS notifications for critical errors
- Metrics dashboard in CloudWatch/Grafana

---

### **8. What I could add in the event of a v2 Production Rollout**

Given more time and resources, this system could be extended with:

#### **Enhanced Error Handling**

- **SQS Dead Letter Queue** - Capture failed validations for retry logic
- **EventBridge → Slack/PagerDuty** - Real-time alerts for bad files
- **CloudWatch Dashboard** - Validation success/failure metrics

#### **Advanced Data Catalog Integration**

- ️ **AWS Glue Data Catalog** - Register validated datasets automatically
- **Athena query support** - SQL queries over validation reports
- **Data quality metrics** - Track quality trends over time

#### **Multi-Environment Infrastructure**

- **Terraform/SAM multi-environment strategy** (dev/staging/prod)
- **Environment-specific IAM roles** with stricter prod policies
- **Blue-green deployments** for zero-downtime updates

#### **Compliance & Governance**

- **Audit logging** - S3 access logs + CloudTrail
- **Encryption at rest** - S3 bucket encryption with KMS
- **Data retention policies** - Lifecycle rules for old reports

---

### **9. Why This Approach Demonstrates Production Thinking**

This project demonstrates:

**Architectural decision-making** - Why event-driven? Why Lambda over EC2?  
**Security engineering** - Least-privilege IAM with scoped policies  
**Operational resilience** - Error handling, logging, monitoring  
**DevOps practices** - CI/CD, IaC, reproducible deployments  
**Real debugging skills** - Solved CloudFormation, IAM, and S3 event issues  
**Documentation discipline** - Comprehensive README, architecture diagrams, runbooks  

---

## 🚀 Quick Start

### Prerequisites

- **AWS Account** with appropriate permissions
- **AWS CLI v2** installed and configured
- **AWS SAM CLI** installed
- **Python 3.10+**
- **Git**

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/serverless-data-qc.git
cd serverless-data-qc/project-01-serverless-data-qc

# Set up environment variables
export AWS_REGION=eu-west-1
export DEPLOY_PROFILE=deploy-ci
export PACKAGING_BUCKET=<your-packaging-bucket>
export INPUT_BUCKET=<account-id>-data-qc-input

# Build the application
sam build

# Deploy to AWS
sam deploy \
  --profile "${DEPLOY_PROFILE}" \
  --stack-name project1-data-qc \
  --s3-bucket "${PACKAGING_BUCKET}" \
  --parameter-overrides InputBucketName="${INPUT_BUCKET}" \
  --region "${AWS_REGION}" \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --no-confirm-changeset
```

### Test the Pipeline

```bash
# Upload a test CSV file
aws s3 cp samples/good.csv s3://${INPUT_BUCKET}/ --profile deploy-ci

# Wait a few seconds for Lambda to process

# Check for the quality report
aws s3 ls s3://${INPUT_BUCKET}/reports/ --profile deploy-ci

# Download and view the report
aws s3 cp s3://${INPUT_BUCKET}/reports/good.csv.json . --profile deploy-ci
cat good.csv.json
```

---

## 📦 Deployment Guide

### Option 1: CLI Deployment (Recommended)

**Using the `deploy-ci` IAM user for automation**

```bash
# 1. Build the Lambda package
sam build

# 2. Deploy with SAM
sam deploy \
  --profile deploy-ci \
  --stack-name project1-data-qc \
  --s3-bucket ${PACKAGING_BUCKET} \
  --parameter-overrides InputBucketName=${INPUT_BUCKET} \
  --region ${AWS_REGION} \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --no-confirm-changeset

# 3. Attach S3 event notifications (if needed)
# Note: May require admin permissions if deploy-ci lacks s3:PutBucketNotification
./infra/bootstrap/attach-s3-notifications.sh
```

### Option 2: AWS Console Deployment (Alternative)

**Using the `devcloud-user` for manual operations**

#### Step 1: Create Lambda Function

1. Navigate to **AWS Lambda Console**
2. Click **"Create function"** → **"Author from scratch"**
3. Function name: `data-qc-lambda`
4. Runtime: **Python 3.10**
5. Click **"Create function"**

#### Step 2: Upload Code

```bash
# Build deployment package locally
sam build
cd .aws-sam/build/DataQCFunction
zip -r ../../../lambda-deployment.zip .
cd ../../..

# Upload via console:
# Lambda → Code tab → Upload from → .zip file → Select lambda-deployment.zip
```

#### Step 3: Configure Environment Variables

| Key | Value |
|-----|-------|
| `BUCKET_NAME` | `<account-id>-data-qc-input` |

#### Step 4: Configure IAM Role

**Option A: Use Auto-Created Role**

Lambda console automatically creates a basic execution role. Add these permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::<account-id>-data-qc-input/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
```

#### Step 5: Add S3 Trigger

1. Go to **S3 Console** → Select input bucket
2. **Properties** tab → **Event notifications** → **Create event notification**
3. Event name: `csv-upload-trigger`
4. Event types: **PUT** (All object create events)
5. Suffix: `.csv`
6. Destination: **Lambda function** → Select `data-qc-lambda`
7. Click **Save changes**

---

## 📁 Project Structure

```
project-01-serverless-data-qc/
│
├── 📂 src/
│   ├── handler.py          # Lambda entry point - receives S3 events
│   ├── validator.py        # Core validation logic - schema, data checks
│   └── utils.py            # Helper functions - S3 operations, logging
│
├── 📂 tests/
│   └── test_validator.py   # Unit tests for validation logic
│
├── 📂 samples/
│   ├── good.csv            # Valid CSV sample for testing
│   └── bad_missing.csv     # Invalid CSV with missing fields
│
├── 📂 diagrams/
│   └── architecture.drawio # Architecture diagram source file
│
├── 📂 evidence/            # Generated after deployment and testing
│   ├── cli/                # CLI command outputs and logs
│   │   ├── 01_s3_listing.txt
│   │   └── reports/        # Downloaded validation reports
│   └── screenshots/        # AWS Console screenshots
│       ├── lambda-config.png
│       ├── iam-policies.png
│       └── s3-events.png
│
├── 📂 infra/
│   ├── bootstrap/
│   │   ├── create-deploy-ci.sh      # Create deployment IAM user
│   │   ├── delete-deploy-ci.sh      # Cleanup deployment user
│   │   └── attach-s3-notifications.sh # Configure S3 events
│   └── policies/
│       ├── deploy-ci-s3-packaging.json    # S3 deployment permissions
│       ├── deploy-ci-cfn-mgmt.json        # CloudFormation permissions
│       ├── deploy-ci-lambda-mgmt.json     # Lambda lifecycle permissions
│       └── deploy-ci-iam-passrole.json    # IAM PassRole permissions
│
├── 📂 .github/
│   └── workflows/
│       └── deploy.yml      # GitHub Actions CI/CD pipeline
│
├── template.yaml           # AWS SAM template (IaC)
├── samconfig.toml          # SAM CLI configuration
├── requirements.txt        # Python dependencies
├── pytest.ini              # Test configuration
└── README.md              # This file
```

---

## 🔒 IAM & Security

### Multi-User Security Model

This project demonstrates **least-privilege IAM design** with role separation:

| IAM User | Purpose | Use For |
|----------|---------|---------|
| **deploy-ci** | Automated deployments, CI/CD | SAM CLI, GitHub Actions, deployment scripts |
| **devcloud-user** | Manual operations, testing | Console uploads, screenshots, manual validation tests |

**Why this separation matters:**

- **Blast radius limitation** - Compromised CI/CD doesn't affect manual operations
- **Audit trail clarity** - CloudTrail clearly shows automated vs. manual changes
- **Compliance requirements** - Separate deployment and operational access (SOC 2, ISO 27001)
- **Professional practice** - Mirrors enterprise security patterns

---

### IAM Policy Architecture

The `deploy-ci` user uses **four scoped policies** implementing least-privilege:

#### 1. **S3 Packaging Policy** (`deploy-ci-s3-packaging.json`)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${PACKAGING_BUCKET}",
        "arn:aws:s3:::${PACKAGING_BUCKET}/*",
        "arn:aws:s3:::${INPUT_BUCKET}",
        "arn:aws:s3:::${INPUT_BUCKET}/*"
      ]
    }
  ]
}
```

**Purpose:** Allows SAM to upload deployment artifacts and test files

---

#### 2. **CloudFormation Management Policy** (`deploy-ci-cfn-mgmt.json`)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudformation:CreateStack",
        "cloudformation:UpdateStack",
        "cloudformation:DeleteStack",
        "cloudformation:DescribeStacks",
        "cloudformation:DescribeStackEvents",
        "cloudformation:GetTemplate"
      ],
      "Resource": "arn:aws:cloudformation:*:*:stack/project1-data-qc/*"
    }
  ]
}
```

**Purpose:** CloudFormation stack operations **scoped to this project only**

**Why the wildcard suffix (`/*`):** CloudFormation creates unique stack IDs

---

#### 3. **Lambda Management Policy** (`deploy-ci-lambda-mgmt.json`)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:CreateFunction",
        "lambda:UpdateFunctionCode",
        "lambda:UpdateFunctionConfiguration",
        "lambda:GetFunction",
        "lambda:AddPermission",
        "lambda:RemovePermission"
      ],
      "Resource": "arn:aws:lambda:*:*:function:project1-data-qc-*"
    }
  ]
}
```

**Purpose:** Lambda lifecycle management **scoped to project functions**

---

#### 4. **IAM PassRole Policy** (`deploy-ci-iam-passrole.json`)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:PassRole",
        "iam:CreateRole",
        "iam:TagRole",
        "iam:GetRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy"
      ],
      "Resource": "arn:aws:iam::*:role/project1-data-qc-*"
    }
  ]
}
```

**Purpose:** Allows CloudFormation to create/manage Lambda execution roles

**Critical note:** `iam:TagRole` is required for CloudFormation resource tracking (non-obvious but mandatory)

---

### Lambda Execution Role

The Lambda function itself has **minimal permissions**:

```yaml
# From template.yaml
Policies:
  - S3ReadPolicy:
      BucketName: !Ref InputBucketName
  - S3WritePolicy:
      BucketName: !Ref InputBucketName
```

**Translates to:**

```json
{
  "Effect": "Allow",
  "Action": [
    "s3:GetObject",
    "s3:PutObject"
  ],
  "Resource": "arn:aws:s3:::<account-id>-data-qc-input/*"
}
```

**Cannot:**

- Delete S3 objects
- Access other S3 buckets
- Modify IAM policies
- Invoke other Lambda functions
- Access DynamoDB or RDS

---

### Security Best Practices Implemented

**Principle of least privilege** - Each role has only the minimum permissions needed  
**Resource-level permissions** - Specific ARNs, not wildcards  
**No hardcoded credentials** - All access via IAM roles  
**Separate deployment and runtime roles** - deploy-ci ≠ Lambda execution role  
**CloudWatch Logs for audit trail** - All Lambda executions logged  
**Scoped to single project** - Policies can't affect other stacks  
**No public S3 access** - Buckets are private by default  
**S3 encryption ready** - Can enable SSE-S3 or SSE-KMS without code changes  

---

### Common IAM Issues and Solutions

| Issue | Root Cause | Solution |
|-------|------------|----------|
| `iam:CreateRole` denied | CloudFormation needs to create Lambda execution role | Add `iam:CreateRole` to deploy-ci policies |
| `iam:TagRole` denied | CFN requires tagging for resource tracking | Add `iam:TagRole` permission (often overlooked) |
| `s3:PutBucketNotification` denied | S3 event configuration requires special permission | Either add permission or use admin for this step |
| `iam:PassRole` denied | CloudFormation can't assign execution role to Lambda | Add scoped PassRole permission |
| Circular dependency in CFN | Role, policy, Lambda have ordering constraints | Use `DependsOn` in template.yaml |

---

## 🧪 Testing & Validation

### Local Unit Tests

```bash
# Install test dependencies
pip install -r requirements.txt
pip install pytest pytest-cov

# Run unit tests
python -m pytest tests/ -v

# Run with coverage report
python -m pytest tests/ --cov=src --cov-report=html

# View coverage report
open htmlcov/index.html
```

### Integration Tests

#### Test Good CSV

```bash
# Upload valid CSV
aws s3 cp samples/good.csv s3://${INPUT_BUCKET}/ --profile deploy-ci

# Wait for Lambda execution (check CloudWatch Logs)
sam logs --stack-name project1-data-qc --tail --profile deploy-ci

# Verify report generated
aws s3 ls s3://${INPUT_BUCKET}/reports/ --profile deploy-ci

# Download and inspect
aws s3 cp s3://${INPUT_BUCKET}/reports/good.csv.json . --profile deploy-ci
cat good.csv.json | jq .
```

Expected report structure:

```json
Here is your JSON **arranged vertically**, with **no changes to any information**:

```json
{
  "num_rows": 25,
  "num_columns": 5,
  "columns_present": [
    "id",
    "name",
    "age",
    "email",
    "signup_date"
  ],
  "row_issues": {},
  "summary": {
    "columns": {
      "id": {
        "non_null_count": 25,
        "unique": 25,
        "dtype": "int64"
      },
      "name": {
        "non_null_count": 25,
        "unique": 25,
        "dtype": "object"
      },
      "age": {
        "non_null_count": 25,
        "unique": 24,
        "dtype": "int64"
      },
      "email": {
        "non_null_count": 19,
        "unique": 19,
        "dtype": "object"
      },
      "signup_date": {
        "non_null_count": 19,
        "unique": 19,
        "dtype": "object"
      }
    }
  },
  "missing_required_columns": [],
  "total_issues": 0
}

```

---

#### Test Bad CSV (Missing Fields)

```bash
# Upload invalid CSV
aws s3 cp samples/bad_missing.csv s3://${INPUT_BUCKET}/ --profile deploy-ci

# Check report
aws s3 cp s3://${INPUT_BUCKET}/reports/bad_missing.csv.json . --profile deploy-ci
cat bad_missing.csv.json | jq .
```

Expected report:

```json
{
  "file": "bad_missing.csv",
  "status": "FAIL",
  "timestamp": "2024-01-15T10:35:00Z",
  "validations": [
    {
      "check": "schema_validation",
      "result": "pass"
    },
    {
      "check": "missing_values",
      "result": "fail",
      "errors": [
        "Column 'age' has 15 missing values",
        "Column 'email' has 3 missing values"
      ]
    }
  ],
  "metadata": {
    "rows": 100,
    "columns": 5,
    "missing_values_count": 18
  }
}
```

---

### Batch Testing (15 Samples)

```bash
# Upload multiple test files
for i in {1..15}; do
  aws s3 cp samples/test_${i}.csv s3://${INPUT_BUCKET}/ --profile deploy-ci
done

# Wait for processing
sleep 30

# Count reports generated
aws s3 ls s3://${INPUT_BUCKET}/reports/ --profile deploy-ci | wc -l

# Download all reports
aws s3 sync s3://${INPUT_BUCKET}/reports/ ./evidence/cli/reports/ --profile deploy-ci

# Analyze pass/fail rates
grep -h '"status"' ./evidence/cli/reports/*.json | sort | uniq -c
```

---

### Evidence Collection

You may document the workflow in this way:

#### CLI Evidence

```bash
# Create evidence directory structure
mkdir -p evidence/{cli,screenshots}

# 1. List S3 input bucket
aws s3 ls s3://${INPUT_BUCKET}/ --recursive --profile deploy-ci \
  > evidence/cli/01_s3_input_listing.txt

# 2. List S3 reports
aws s3 ls s3://${INPUT_BUCKET}/reports/ --recursive --profile deploy-ci \
  > evidence/cli/02_s3_reports_listing.txt

# 3. Download all reports
aws s3 sync s3://${INPUT_BUCKET}/reports/ evidence/cli/reports/ \
  --profile deploy-ci

# 4. Capture CloudWatch logs
sam logs --stack-name project1-data-qc --profile deploy-ci \
  > evidence/cli/03_cloudwatch_logs.txt

# 5. Describe CloudFormation stack
aws cloudformation describe-stacks \
  --stack-name project1-data-qc \
  --profile deploy-ci \
  > evidence/cli/04_cfn_stack_description.json

# 6. List Lambda functions
aws lambda list-functions --profile deploy-ci \
  | jq '.Functions[] | select(.FunctionName | startswith("project1-data-qc"))' \
  > evidence/cli/05_lambda_functions.json
```

---

#### Console Screenshots Checklist

Capture screenshots and save to `evidence/screenshots/`:

**Lambda Console:**
- `lambda-01-configuration.png` - Function configuration tab
- `lambda-02-permissions.png` - IAM role and resource policies
- `lambda-03-triggers.png` - S3 trigger configuration
- `lambda-04-monitoring.png` - CloudWatch metrics dashboard

**S3 Console:**
- `s3-01-input-bucket.png` - Input bucket contents
- `s3-02-reports-folder.png` - Reports prefix contents
- `s3-03-event-notifications.png` - Event notification configuration
- `s3-04-file-properties.png` - Individual file properties

**CloudWatch Console:**
- `cloudwatch-01-log-groups.png` - Lambda log groups
- `cloudwatch-02-log-stream.png` - Specific execution log stream
- `cloudwatch-03-validation-logs.png` - Validation success/failure logs

**IAM Console:**
- `iam-01-deploy-ci-policies.png` - deploy-ci user policies
- `iam-02-lambda-execution-role.png` - Lambda execution role
- `iam-03-trust-relationships.png` - Role trust policy

**CloudFormation Console:**
- `cfn-01-stack-overview.png` - Stack overview
- `cfn-02-resources.png` - Resources created
- `cfn-03-events.png` - Stack events log
- `cfn-04-template.png` - Template view

---

## 🔧 Troubleshooting

### Common Issues and Solutions

#### 1. Lambda Not Triggering

**Symptoms:**
- Files uploaded to S3 but no reports generated
- No CloudWatch logs appearing

**Diagnosis:**
```bash
# Check if S3 event notification is configured
aws s3api get-bucket-notification-configuration \
  --bucket ${INPUT_BUCKET} \
  --profile deploy-ci

# Check Lambda permissions
aws lambda get-policy \
  --function-name project1-data-qc-DataQCFunction-XXXXX \
  --profile deploy-ci
```

**Solutions:**

**A. S3 Event Not Configured**

```bash
# Re-run attachment script
./infra/bootstrap/attach-s3-notifications.sh
```

**B. Lambda Lacks S3 Invoke Permission**

```bash
# Add permission manually
aws lambda add-permission \
  --function-name project1-data-qc-DataQCFunction-XXXXX \
  --statement-id AllowS3Invoke \
  --action lambda:InvokeFunction \
  --principal s3.amazonaws.com \
  --source-arn arn:aws:s3:::${INPUT_BUCKET} \
  --profile deploy-ci
```

---

#### 2. IAM Permission Errors During Deployment

**Symptoms:**
- `AccessDenied` errors during `sam deploy`
- CloudFormation rollback due to IAM issues

**Common Errors:**

**A. `iam:TagRole` Denied**

```
Error: User: arn:aws:iam::123456789012:user/deploy-ci is not authorized 
to perform: iam:TagRole on resource: role project1-data-qc-LambdaRole
```

**Solution:**

Add to `deploy-ci-iam-passrole.json`:

```json
{
  "Effect": "Allow",
  "Action": ["iam:TagRole"],
  "Resource": "arn:aws:iam::*:role/project1-data-qc-*"
}
```

**B. `iam:CreateRole` Denied**

```
Error: User: arn:aws:iam::123456789012:user/deploy-ci is not authorized 
to perform: iam:CreateRole
```

**Solution:**

Add to `deploy-ci-iam-passrole.json`:

```json
{
  "Effect": "Allow",
  "Action": ["iam:CreateRole"],
  "Resource": "arn:aws:iam::*:role/project1-data-qc-*"
}
```

**C. `s3:PutBucketNotification` Denied**

```
Error: User: arn:aws:iam::123456789012:user/deploy-ci is not authorized 
to perform: s3:PutBucketNotification on resource: bucket/<INPUT_BUCKET>
```

**Solutions:**

**Option 1:** Add permission to deploy-ci (not recommended - broad permission)

**Option 2:** Use admin user to run `attach-s3-notifications.sh` (recommended)

---

#### 3. SAM Build Failures

**Symptoms:**
- `sam build` fails with pip errors
- Dependencies not installing correctly

**Diagnosis:**
```bash
# Check Python version
python --version  # Should be 3.10+

# Check SAM CLI version
sam --version

# Check for corrupted venv
ls -la .aws-sam/
```

**Solutions:**

**A. Clean and Rebuild**

```bash
# Remove build artifacts
rm -rf .aws-sam/

# Rebuild
sam build --use-container
```

**B. Use Container Build (Isolates Environment)**

```bash
# Build inside Docker container (most reliable)
sam build --use-container --container-image public.ecr.aws/sam/build-python3.10
```

**C. Check requirements.txt**

```bash
# Verify requirements.txt format
cat requirements.txt

# Should contain:
# pandas>=2.0.0
# boto3>=1.26.0
```

---

#### 4. Lambda Execution Timeouts

**Symptoms:**
- Large CSV files not completing validation
- Lambda timeout errors in CloudWatch Logs

**Diagnosis:**
```bash
# Check current timeout
aws lambda get-function-configuration \
  --function-name project1-data-qc-DataQCFunction-XXXXX \
  --query 'Timeout' \
  --profile deploy-ci
```

**Solution:**

Update `template.yaml`:

```yaml
Resources:
  DataQCFunction:
    Type: AWS::Serverless::Function
    Properties:
      Timeout: 300  # Increase from default 3 seconds to 5 minutes
      MemorySize: 512  # Increase memory for pandas operations
```

Redeploy:

```bash
sam build && sam deploy --no-confirm-changeset --profile deploy-ci
```

---

#### 5. CloudFormation Stack Stuck in UPDATE_ROLLBACK_FAILED

**Symptoms:**
- Stack cannot be updated or deleted
- Console shows `UPDATE_ROLLBACK_FAILED` status

**Diagnosis:**
```bash
# Check stack events
aws cloudformation describe-stack-events \
  --stack-name project1-data-qc \
  --profile deploy-ci \
  | jq '.StackEvents[] | select(.ResourceStatus | contains("FAILED"))'
```

**Solution:**

**Option 1: Continue Update Rollback**

```bash
aws cloudformation continue-update-rollback \
  --stack-name project1-data-qc \
  --profile deploy-ci
```

**Option 2: Force Delete (Nuclear Option)**

```bash
# Delete stack (may leave orphaned resources)
aws cloudformation delete-stack \
  --stack-name project1-data-qc \
  --profile deploy-ci

# Manually clean up orphaned resources
aws lambda delete-function --function-name project1-data-qc-DataQCFunction-XXXXX
aws iam delete-role --role-name project1-data-qc-LambdaRole-XXXXX
```

---

### Debug Commands

#### Check Lambda Logs in Real-Time

```bash
# Tail Lambda logs (Ctrl+C to stop)
sam logs --stack-name project1-data-qc --tail --profile deploy-ci
```

#### Validate SAM Template Syntax

```bash
# Check for YAML/CloudFormation errors
sam validate --profile deploy-ci

# Check for linting issues (requires cfn-lint)
pip install cfn-lint
cfn-lint template.yaml
```

#### Test Lambda Locally

```bash
# Create test event
cat > events/test-s3-event.json <<EOF
{
  "Records": [
    {
      "s3": {
        "bucket": {"name": "${INPUT_BUCKET}"},
        "object": {"key": "samples/good.csv"}
      }
    }
  ]
}
EOF

# Invoke locally
sam local invoke DataQCFunction -e events/test-s3-event.json
```

#### List All Stack Resources

```bash
# See all resources created by CloudFormation
aws cloudformation describe-stack-resources \
  --stack-name project1-data-qc \
  --profile deploy-ci \
  | jq '.StackResources[] | {Type: .ResourceType, LogicalId: .LogicalResourceId, PhysicalId: .PhysicalResourceId}'
```

#### Check S3 Event Configuration

```bash
# Verify event notification is configured correctly
aws s3api get-bucket-notification-configuration \
  --bucket ${INPUT_BUCKET} \
  --profile deploy-ci \
  | jq '.LambdaFunctionConfigurations'
```

---

### Enable Detailed Lambda Logging

Modify `src/handler.py`:

```python
import logging
import json

# Configure logger
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)  # Change from INFO to DEBUG

def lambda_handler(event, context):
    # Log entire event payload
    logger.debug(f"Received event: {json.dumps(event)}")
    
    # Your existing code...
    
    # Log intermediate steps
    logger.debug(f"Downloading file from S3: {bucket}/{key}")
    logger.debug(f"Validation results: {validation_results}")
```

Redeploy and check logs:

```bash
sam build && sam deploy --no-confirm-changeset --profile deploy-ci
sam logs --stack-name project1-data-qc --tail --profile deploy-ci
```

---

<div align="center">

**⭐ If you find this project helpful, please consider giving it a star! ⭐**

/div>
