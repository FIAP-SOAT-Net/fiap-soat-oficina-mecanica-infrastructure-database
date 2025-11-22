# Smart Mechanical Workshop - Database Infrastructure

Infrastructure as Code (IaC) for the Smart Mechanical Workshop database using AWS RDS MySQL 8.4, Terraform, Flyway migrations, and GitHub Actions CI/CD.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Local Development](#local-development)
- [AWS Deployment](#aws-deployment)
- [Database Migrations](#database-migrations)
- [CI/CD Pipeline](#cicd-pipeline)
- [Cost Optimization](#cost-optimization)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

This repository manages the complete database infrastructure for the Smart Mechanical Workshop project, including:

- **AWS RDS MySQL 8.4** - Managed database service
- **Terraform** - Infrastructure as Code for AWS resources
- **Flyway** - Database migration management
- **Docker Compose** - Local development environment
- **GitHub Actions** - Automated CI/CD pipeline

## 🏗️ Architecture

### Development Environment
```
┌─────────────────────────────────────────┐
│         Developer Machine               │
│  ┌──────────────────────────────────┐  │
│  │   Docker Compose                  │  │
│  │   ├── MySQL 8.4 Container        │  │
│  │   └── Flyway Container           │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### AWS Production Environment
```
┌────────────────────────────────────────────────────┐
│                     AWS Cloud                       │
│  ┌──────────────────────────────────────────────┐ │
│  │              VPC (Your VPC)                   │ │
│  │  ┌────────────────────────────────────────┐  │ │
│  │  │  RDS MySQL 8.4 (Publicly Accessible)  │  │ │
│  │  │  - db.t4g.micro (~$12/month)           │  │ │
│  │  │  - 20GB gp3 Storage                    │  │ │
│  │  │  - Single-AZ (dev)                     │  │ │
│  │  │  - Encrypted at rest                   │  │ │
│  │  └────────────────────────────────────────┘  │ │
│  │                      ↑                        │ │
│  │  ┌──────────────────┴─────────────────────┐  │ │
│  │  │      Security Group                    │  │ │
│  │  │      - Port 3306                       │  │ │
│  │  │      - Your IP: X.X.X.X/32            │  │ │
│  │  │      - EKS SG: sg-xxxxxxxx            │  │ │
│  │  └────────────────────────────────────────┘  │ │
│  └──────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────┘
         ↑                              ↑
         │                              │
    Your Machine                    EKS Cluster
```

## ✅ Prerequisites

### Local Development
- [Docker](https://docs.docker.com/get-docker/) (20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (2.0+)
- [MySQL Client](https://dev.mysql.com/downloads/shell/) (optional, for CLI access)

### AWS Deployment
- [AWS CLI](https://aws.amazon.com/cli/) (2.x)
- [Terraform](https://www.terraform.io/downloads) (1.6+)
- AWS Account with appropriate permissions
- GitHub account with repository access

### Required AWS Resources
- VPC with at least 2 subnets (different AZs)
- (Optional) EKS cluster security group for application access

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/FIAP-SOAT-Net/fiap-soat-oficina-mecanica-infrastructure-database.git
cd fiap-soat-oficina-mecanica-infrastructure-database
```

### 2. Local Development Setup
```bash
# Copy environment file
cp .env.example .env

# Edit .env with your preferred settings
nano .env

# Start MySQL and run migrations
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f mysql
```

### 3. Connect to Local Database
```bash
# Using mysql client
mysql -h 127.0.0.1 -P 3306 -u workshop_user -p smart_workshop

# Or using docker exec
docker exec -it smart-workshop-db mysql -u workshop_user -p smart_workshop
```

## 💻 Local Development

### Starting the Environment
```bash
# Start all services
docker-compose up -d

# Start only MySQL (without Flyway auto-migration)
docker-compose up -d mysql
```

### Running Migrations Manually
```bash
# Using Flyway container
docker-compose run --rm flyway migrate

# View migration history
docker-compose run --rm flyway info

# Validate migrations
docker-compose run --rm flyway validate
```

### Stopping the Environment
```bash
# Stop services
docker-compose down

# Stop and remove volumes (⚠️ deletes all data)
docker-compose down -v
```

### Adding New Migrations

Create new SQL files in `migrations/sql/` following the naming convention:

```
migrations/sql/
├── V1__create_initial_schema.sql
├── V2__add_customers_table.sql
├── V3__add_vehicles_table.sql
└── V4__seed_initial_data.sql
```

**Naming Convention:** `V{version}__{description}.sql`
- Version must be incremental (V1, V2, V3...)
- Use double underscore `__` between version and description
- Description should be lowercase with underscores

## ☁️ AWS Deployment

### Step 1: Configure AWS Credentials

#### Option A: Using AWS CLI
```bash
aws configure
```

#### Option B: Using OIDC (Recommended for CI/CD)
Follow the [AWS OIDC Guide](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)

### Step 2: Prepare Terraform Variables

```bash
cd terraform

# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

**Required values:**
```hcl
vpc_id     = "vpc-xxxxxxxxxxxxxxxxx"  # Your VPC ID
subnet_ids = [
  "subnet-xxxxxxxxxxxxxxxxx",  # Subnet in AZ 1
  "subnet-xxxxxxxxxxxxxxxxx",  # Subnet in AZ 2
]

# Get your public IP: https://whatismyipaddress.com/
allowed_cidr_blocks = [
  "YOUR_IP_ADDRESS/32",
]

# Optional: EKS security group
allowed_security_group_ids = [
  "sg-xxxxxxxxxxxxxxxxx",  # EKS security group
]
```

### Step 3: Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Preview changes
terraform plan

# Apply changes
terraform apply

# Get RDS endpoint
terraform output rds_endpoint
```

### Step 4: Get Database Password

The password is automatically generated and stored in AWS Secrets Manager:

```bash
# Get the secret ARN
SECRET_ARN=$(terraform output -raw db_password_secret_arn)

# Retrieve password
aws secretsmanager get-secret-value \
  --secret-id $SECRET_ARN \
  --query SecretString \
  --output text | jq -r .password
```

### Step 5: Connect to RDS

```bash
# Get connection command from Terraform
terraform output mysql_cli_command

# Example:
mysql -h smart-workshop-dev-xxxxx.us-east-1.rds.amazonaws.com \
      -P 3306 \
      -u admin \
      -p \
      smart_workshop
```

### Step 6: Run Migrations on RDS

```bash
# Copy Flyway config
cp flyway.conf.example flyway.conf

# Edit flyway.conf with RDS endpoint and password
nano flyway.conf

# Run migrations using local Flyway
flyway migrate

# Or using Docker
docker run --rm \
  -v $(pwd)/migrations/sql:/flyway/sql \
  -e FLYWAY_URL="jdbc:mysql://YOUR_RDS_ENDPOINT:3306/smart_workshop" \
  -e FLYWAY_USER="admin" \
  -e FLYWAY_PASSWORD="YOUR_PASSWORD" \
  flyway/flyway:10-alpine migrate
```

## 🔄 Database Migrations

### Flyway Basics

Flyway tracks migrations using a `flyway_schema_history` table:

```sql
SELECT * FROM flyway_schema_history;
```

### Migration States

- ✅ **Success** - Migration applied successfully
- ⏳ **Pending** - Not yet applied
- ❌ **Failed** - Migration failed (needs manual fix)

### Best Practices

1. **Never modify applied migrations** - Create a new migration instead
2. **Test locally first** - Always test migrations with Docker Compose
3. **Use transactions** - Wrap DDL in transactions when possible
4. **Backup before production** - Take snapshot before major changes
5. **Keep migrations small** - One logical change per migration

### Common Commands

```bash
# Apply pending migrations
flyway migrate

# View migration status
flyway info

# Validate applied migrations
flyway validate

# Clean database (⚠️ development only)
flyway clean
```

## 🔄 CI/CD Pipeline

### GitHub Actions Workflows

#### 1. **SQL Validation** (`sql-validation.yml`)
Triggers on: PR or push to `main` with SQL changes

- Validates SQL syntax
- Runs Flyway validate
- Lints SQL files with sqlfluff

#### 2. **Terraform Validate** (`terraform-validate.yml`)
Triggers on: PR or push to `main` with Terraform changes

- Checks Terraform formatting
- Validates Terraform configuration
- Comments results on PR

#### 3. **Terraform Plan** (`terraform-plan.yml`)
Triggers on: PR with Terraform changes

- Generates Terraform plan
- Comments plan on PR for review
- Requires AWS credentials configured

#### 4. **Deploy Infrastructure** (`terraform-deploy.yml`)
Triggers on: Push to `main` or manual workflow dispatch

- Applies Terraform changes
- Deploys/updates RDS instance
- Runs Flyway migrations automatically

### Setting Up CI/CD

#### Step 1: Configure GitHub Secrets

Go to repository Settings → Secrets and variables → Actions

**Required Secrets:**
```
AWS_ROLE_ARN              # OIDC role ARN for GitHub Actions
VPC_ID                    # Your VPC ID
SUBNET_IDS                # JSON array: ["subnet-xxx", "subnet-yyy"]
ALLOWED_CIDR_BLOCKS       # JSON array: ["X.X.X.X/32"]
```

**Optional Variables:**
```
AWS_REGION                # Default: us-east-1
```

#### Step 2: Create GitHub Environment

1. Go to Settings → Environments
2. Create environment named `dev`
3. (Optional) Add protection rules for approvals

#### Step 3: Configure AWS OIDC

Create an IAM role for GitHub Actions:

```bash
# Use the provided script or follow AWS documentation
# https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services
```

### Manual Deployment

Trigger manual deployment:

1. Go to Actions tab
2. Select "Deploy Infrastructure"
3. Click "Run workflow"
4. Choose action: `apply` or `destroy`
5. Click "Run workflow"

## 💰 Cost Optimization

### Current Configuration (Dev)

| Resource | Specification | Estimated Cost/Month |
|----------|--------------|---------------------|
| RDS MySQL | db.t4g.micro | ~$12.00 |
| Storage | 20GB gp3 | ~$2.00 |
| Backup | 7 days retention | ~$0.50 |
| **Total** | | **~$14.50/month** |

### Cost-Saving Tips

#### 1. Stop RDS When Not in Use
```bash
# Stop RDS instance
aws rds stop-db-instance --db-instance-identifier smart-workshop-dev-xxxxx

# Start RDS instance
aws rds start-db-instance --db-instance-identifier smart-workshop-dev-xxxxx
```

⚠️ **Note:** RDS auto-starts after 7 days

#### 2. Automate Start/Stop Schedule

Create a Lambda function or use AWS Instance Scheduler:
- Start: Monday 9 AM
- Stop: Friday 6 PM
- **Savings: ~40-50%** (~$6-7/month)

#### 3. Use Spot Instances for Bastion (if needed)

If you add a bastion host:
- t4g.nano spot: ~$1-2/month (vs ~$3 on-demand)

#### 4. Optimize Storage

```hcl
# Reduce storage for very light usage
db_allocated_storage = 20  # Minimum for gp3

# Disable autoscaling if not needed
db_max_allocated_storage = 0
```

#### 5. Reduce Backup Retention

```hcl
# Minimum retention for dev
backup_retention_period = 1  # Instead of 7
```

## 🔧 Troubleshooting

### Local Development Issues

#### Container won't start
```bash
# Check logs
docker-compose logs mysql

# Common fixes:
docker-compose down -v  # Remove volumes
docker-compose up -d    # Restart
```

#### Can't connect to MySQL
```bash
# Check if container is running
docker-compose ps

# Check MySQL is healthy
docker-compose exec mysql mysqladmin -p ping

# Check port binding
netstat -an | grep 3306
```

#### Flyway migration fails
```bash
# Check Flyway logs
docker-compose logs flyway

# Manually repair (if needed)
docker-compose run --rm flyway repair

# Re-run migrations
docker-compose run --rm flyway migrate
```

### AWS Deployment Issues

#### Terraform apply fails
```bash
# Check AWS credentials
aws sts get-caller-identity

# Validate Terraform
terraform validate

# Check state
terraform show
```

#### Can't connect to RDS
```bash
# Check security group rules
aws ec2 describe-security-groups --group-ids sg-xxxxx

# Verify your current IP
curl https://checkip.amazonaws.com

# Test connection
telnet your-rds-endpoint.rds.amazonaws.com 3306
```

#### RDS password unknown
```bash
# Get from Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id <secret-arn> \
  --query SecretString \
  --output text | jq -r .password
```

#### Migration fails on RDS
```bash
# Check Flyway history
docker run --rm \
  -e FLYWAY_URL="jdbc:mysql://RDS_ENDPOINT:3306/smart_workshop" \
  -e FLYWAY_USER="admin" \
  -e FLYWAY_PASSWORD="PASSWORD" \
  flyway/flyway:10-alpine info

# If migration is stuck, repair
flyway repair
```

### GitHub Actions Issues

#### Workflow fails with AWS credentials
- Verify OIDC role is configured correctly
- Check `AWS_ROLE_ARN` secret is set
- Ensure trust policy allows GitHub Actions

#### Terraform plan shows unexpected changes
- Check if someone manually modified resources
- Verify terraform.tfvars matches AWS state
- Consider importing manual changes: `terraform import`

## 📚 Additional Resources

- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [MySQL 8.4 Documentation](https://dev.mysql.com/doc/refman/8.4/en/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Flyway Documentation](https://flywaydb.org/documentation/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Test locally with Docker Compose
4. Create a Pull Request
5. Wait for CI/CD validation
6. Get approval and merge

## 📝 License

This project is part of the FIAP SOAT program.

## 👥 Team

**FIAP SOAT - Smart Mechanical Workshop Team**

---

**Last Updated:** November 2025