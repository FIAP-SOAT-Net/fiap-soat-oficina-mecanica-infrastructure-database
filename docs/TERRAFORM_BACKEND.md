# Terraform Backend Setup

This directory contains scripts to set up the Terraform remote state backend using S3 and DynamoDB.

## Why Remote State?

Terraform state contains sensitive information and should be:
- Stored securely in S3 with encryption
- Protected with state locking using DynamoDB
- Versioned for rollback capability

## Setup Instructions

### 1. Create S3 Bucket and DynamoDB Table

```bash
# Set your variables
AWS_REGION="us-east-1"
PROJECT_NAME="smart-workshop"
ENVIRONMENT="dev"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create S3 bucket for state
aws s3api create-bucket \
  --bucket "${PROJECT_NAME}-${ENVIRONMENT}-terraform-state-${AWS_ACCOUNT_ID}" \
  --region ${AWS_REGION}

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket "${PROJECT_NAME}-${ENVIRONMENT}-terraform-state-${AWS_ACCOUNT_ID}" \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket "${PROJECT_NAME}-${ENVIRONMENT}-terraform-state-${AWS_ACCOUNT_ID}" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket "${PROJECT_NAME}-${ENVIRONMENT}-terraform-state-${AWS_ACCOUNT_ID}" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name "${PROJECT_NAME}-${ENVIRONMENT}-terraform-lock" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ${AWS_REGION}
```

### 2. Configure Terraform Backend

Update `terraform/main.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "smart-workshop-dev-terraform-state-YOUR_ACCOUNT_ID"
    key            = "smart-workshop/database/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "smart-workshop-dev-terraform-lock"
  }
}
```

### 3. Migrate Existing State (if needed)

```bash
cd terraform

# Initialize with new backend
terraform init -migrate-state

# Verify
terraform state list
```

## Cost

- **S3**: ~$0.023/GB/month (negligible for state files)
- **DynamoDB**: Free tier covers locking (pay-per-request)
- **Total**: < $1/month

## Cleanup

```bash
# ⚠️ Only if destroying everything
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Delete state (after terraform destroy)
aws s3 rb s3://smart-workshop-dev-terraform-state-${AWS_ACCOUNT_ID} --force

# Delete lock table
aws dynamodb delete-table --table-name smart-workshop-dev-terraform-lock
```
