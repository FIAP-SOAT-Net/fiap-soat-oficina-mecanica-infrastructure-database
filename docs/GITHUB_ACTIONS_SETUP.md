# GitHub Actions Setup Guide

Complete guide to configure GitHub Actions for automated CI/CD.

## Prerequisites

- GitHub repository with admin access
- AWS account with appropriate permissions
- AWS CLI configured locally

## Step 1: Configure AWS OIDC for GitHub Actions

### Why OIDC?

OIDC (OpenID Connect) is more secure than using static AWS access keys:
- ✅ No long-lived credentials stored in GitHub
- ✅ Temporary credentials with automatic rotation
- ✅ Fine-grained permissions per workflow
- ✅ Audit trail in CloudTrail

### Create OIDC Provider

```bash
# Create OIDC provider in AWS (one-time setup)
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### Create IAM Role for GitHub Actions

Create file `github-actions-role-trust-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:FIAP-SOAT-Net/fiap-soat-oficina-mecanica-infrastructure-database:*"
        }
      }
    }
  ]
}
```

Create the role:

```bash
# Replace YOUR_ACCOUNT_ID
aws iam create-role \
  --role-name GitHubActionsSmartWorkshopDB \
  --assume-role-policy-document file://github-actions-role-trust-policy.json
```

### Attach Permissions Policy

Create file `github-actions-permissions.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "rds:*",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeVpcs",
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:CreateTags",
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "iam:CreateRole",
        "iam:GetRole",
        "iam:DeleteRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PassRole",
        "iam:TagRole"
      ],
      "Resource": "*"
    }
  ]
}
```

Attach policy:

```bash
aws iam put-role-policy \
  --role-name GitHubActionsSmartWorkshopDB \
  --policy-name TerraformRDSPolicy \
  --policy-document file://github-actions-permissions.json
```

Get the Role ARN:

```bash
aws iam get-role \
  --role-name GitHubActionsSmartWorkshopDB \
  --query 'Role.Arn' \
  --output text
```

## Step 2: Configure GitHub Repository Secrets

### Navigate to Secrets

1. Go to your repository on GitHub
2. Click **Settings** → **Secrets and variables** → **Actions**

### Add Repository Secrets

Click **New repository secret** for each:

| Secret Name | Description | Example Value |
|------------|-------------|---------------|
| `AWS_ROLE_ARN` | IAM Role ARN from Step 1 | `arn:aws:iam::123456789012:role/GitHubActionsSmartWorkshopDB` |
| `VPC_ID` | Your VPC ID | `vpc-0abcd1234efgh5678` |
| `SUBNET_IDS` | JSON array of subnet IDs | `["subnet-xxx", "subnet-yyy"]` |
| `ALLOWED_CIDR_BLOCKS` | JSON array of allowed IPs | `["203.0.113.0/32"]` |

### Optional: Add Variables

Click **Variables** tab → **New repository variable**:

| Variable Name | Description | Example Value |
|--------------|-------------|---------------|
| `AWS_REGION` | AWS Region | `us-east-1` |

## Step 3: Create GitHub Environment

### Why Environments?

Environments provide:
- Protection rules (require approvals)
- Environment-specific secrets
- Deployment history

### Create Environment

1. Go to **Settings** → **Environments**
2. Click **New environment**
3. Name: `dev`
4. (Optional) Add protection rules:
   - ✅ Required reviewers
   - ✅ Wait timer
   - ✅ Deployment branches (only `main`)

## Step 4: Test the Workflows

### Test Validation Workflow

```bash
# Make a change to terraform files
echo "# Test comment" >> terraform/variables.tf

# Commit and push
git add terraform/variables.tf
git commit -m "test: trigger validation workflow"
git push origin main
```

Check Actions tab - you should see "Terraform Validate" running.

### Test Plan Workflow

```bash
# Create a branch
git checkout -b test-plan

# Make a change
echo "# Another test" >> terraform/variables.tf

# Push and create PR
git add terraform/variables.tf
git commit -m "test: trigger plan workflow"
git push origin test-plan
```

Create PR on GitHub - workflow will comment with Terraform plan.

### Test Deploy Workflow

After merging PR to `main`, the deploy workflow will automatically run.

Or trigger manually:
1. Go to **Actions** tab
2. Select **Deploy Infrastructure**
3. Click **Run workflow**
4. Select branch: `main`
5. Action: `apply`
6. Click **Run workflow**

## Step 5: Monitor Deployments

### View Workflow Runs

- Go to **Actions** tab
- Click on workflow run to see details
- Expand steps to view logs

### Check RDS Deployment

```bash
# After successful deployment
aws rds describe-db-instances \
  --db-instance-identifier smart-workshop-dev-xxxxx
```

## Troubleshooting

### Error: "Error assuming role"

**Problem:** GitHub Actions can't assume the IAM role

**Solutions:**
1. Verify OIDC provider exists:
   ```bash
   aws iam list-open-id-connect-providers
   ```

2. Check role trust policy matches your repository:
   ```bash
   aws iam get-role \
     --role-name GitHubActionsSmartWorkshopDB \
     --query 'Role.AssumeRolePolicyDocument'
   ```

3. Ensure `AWS_ROLE_ARN` secret is correct

### Error: "VPC not found"

**Problem:** Invalid VPC ID in secrets

**Solutions:**
1. Verify VPC exists:
   ```bash
   aws ec2 describe-vpcs --vpc-ids vpc-xxxxx
   ```

2. Check `VPC_ID` secret is correct (no extra spaces)

### Error: "Invalid subnet"

**Problem:** Subnet IDs format incorrect

**Solutions:**
1. Ensure `SUBNET_IDS` is valid JSON array:
   ```json
   ["subnet-xxx", "subnet-yyy"]
   ```

2. Verify subnets exist in your VPC:
   ```bash
   aws ec2 describe-subnets --subnet-ids subnet-xxx subnet-yyy
   ```

### Error: "Terraform state locked"

**Problem:** Previous run didn't complete properly

**Solutions:**
1. Check DynamoDB lock table
2. Manually remove lock (if safe):
   ```bash
   terraform force-unlock LOCK_ID
   ```

## Security Best Practices

1. **Rotate credentials regularly** - OIDC handles this automatically
2. **Use environment protection rules** for production
3. **Limit IAM role permissions** to minimum required
4. **Enable CloudTrail** to audit all API calls
5. **Review workflow logs** regularly
6. **Use branch protection** rules on `main`

## Cost Considerations

GitHub Actions usage:
- Public repositories: Unlimited free minutes
- Private repositories: 2,000 free minutes/month

Typical usage for this project:
- ~5-10 minutes per deployment
- ~200 deployments/month = ~2,000 minutes
- **Cost: Free** (within limits)

## Additional Resources

- [GitHub Actions OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [AWS IAM Roles for GitHub Actions](https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/)
- [Terraform AWS Provider Authentication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration)
