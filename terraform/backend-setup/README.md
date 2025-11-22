# Terraform Backend Setup

This directory contains the infrastructure needed to store Terraform state remotely.

## What it creates

- **S3 Bucket**: Stores Terraform state files with versioning and encryption
- **DynamoDB Table**: Provides state locking to prevent concurrent modifications

## One-time setup

Run this **once** before using the main Terraform configuration:

```bash
cd terraform/backend-setup
terraform init
terraform apply
```

This will create:
- S3 bucket: `smart-workshop-terraform-state`
- DynamoDB table: `smart-workshop-terraform-locks`

## After setup

Once the backend resources are created, you can use the main Terraform configuration with remote state:

```bash
cd ../  # back to terraform/
terraform init  # This will migrate local state to S3
terraform plan
terraform apply
```

## Cost

- **S3**: ~$0.023 per GB per month (state files are typically < 1 MB)
- **DynamoDB**: Pay-per-request (essentially free for this use case)
- **Total**: < $0.10 per month

## Manual cleanup (if needed)

If you need to destroy everything:

```bash
# Delete state bucket (careful!)
aws s3 rm s3://smart-workshop-terraform-state --recursive
terraform destroy
```
