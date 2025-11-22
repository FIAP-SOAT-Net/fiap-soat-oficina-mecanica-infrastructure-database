# Project Structure

Complete overview of the Smart Mechanical Workshop Database Infrastructure project.

## 📁 Directory Structure

```
fiap-soat-oficina-mecanica-infrastructure-database/
├── .github/
│   └── workflows/              # GitHub Actions CI/CD pipelines
│       ├── terraform-validate.yml    # Terraform validation
│       ├── terraform-plan.yml        # Terraform plan on PRs
│       ├── terraform-deploy.yml      # Deploy to AWS
│       └── sql-validation.yml        # SQL syntax validation
│
├── docs/                       # Documentation
│   ├── GITHUB_ACTIONS_SETUP.md      # CI/CD setup guide
│   ├── MIGRATION_GUIDE.md           # Migration guide
│   ├── SQL_STYLE_GUIDE.md           # SQL coding standards
│   └── TERRAFORM_BACKEND.md         # Remote state setup
│
├── migrations/
│   └── sql/                    # Flyway migrations
│       ├── V1__create_initial_schema.sql
│       ├── V2__create_indexes.sql
│       └── V3__seed_service_types.sql
│
├── scripts/
│   └── setup.sh                # Quick setup script
│
├── terraform/                  # Infrastructure as Code
│   ├── main.tf                 # Provider configuration
│   ├── variables.tf            # Variable definitions
│   ├── outputs.tf              # Output definitions
│   ├── rds.tf                  # RDS resources
│   ├── terraform.tfvars.example    # Example configuration
│   └── .terraform/             # Terraform cache (gitignored)
│
├── .env.example                # Local environment variables template
├── .gitignore                  # Git ignore rules
├── docker-compose.yml          # Local development environment
├── flyway.conf.example         # Flyway configuration template
├── Makefile                    # Automation commands
└── README.md                   # Main documentation
```

## 🎯 Key Files Explained

### Root Level

- **`docker-compose.yml`**: Orchestrates MySQL and Flyway containers for local development
- **`.env.example`**: Template for local database credentials
- **`flyway.conf.example`**: Template for Flyway configuration
- **`Makefile`**: Automation commands for common tasks
- **`README.md`**: Complete project documentation

### Terraform Directory

All AWS infrastructure code:

- **`main.tf`**: AWS provider, region, and tags configuration
- **`variables.tf`**: All configurable parameters with defaults
- **`outputs.tf`**: Outputs like RDS endpoint, connection strings
- **`rds.tf`**: RDS instance, security groups, parameter groups
- **`terraform.tfvars.example`**: Example values (copy to terraform.tfvars)

### Migrations Directory

Flyway versioned SQL migrations:

- **Naming**: `V{version}__{description}.sql`
- **V1**: Initial schema (tables)
- **V2**: Performance indexes
- **V3**: Seed data (service types)

### GitHub Workflows

Automated CI/CD pipelines:

- **`terraform-validate.yml`**: Runs on PR, validates Terraform code
- **`terraform-plan.yml`**: Runs on PR, shows infrastructure changes
- **`terraform-deploy.yml`**: Deploys to AWS on merge to main
- **`sql-validation.yml`**: Validates SQL syntax and Flyway migrations

### Documentation

Comprehensive guides:

- **`GITHUB_ACTIONS_SETUP.md`**: Complete CI/CD configuration
- **`MIGRATION_GUIDE.md`**: How to create and manage migrations
- **`SQL_STYLE_GUIDE.md`**: SQL coding standards
- **`TERRAFORM_BACKEND.md`**: Remote state configuration

## 🚀 Quick Start Commands

### Local Development
```bash
make setup           # Create config files
make local-up        # Start MySQL
make local-migrate   # Run migrations
make local-connect   # Connect to database
make local-down      # Stop MySQL
```

### AWS Deployment
```bash
make terraform-init     # Initialize Terraform
make terraform-plan     # Preview changes
make terraform-apply    # Deploy to AWS
make terraform-destroy  # Destroy resources
```

### RDS Management
```bash
make rds-status     # Check RDS status
make rds-password   # Get RDS password
make rds-stop       # Stop RDS (save costs)
make rds-start      # Start RDS
```

### Utilities
```bash
make help           # Show all commands
make ci-validate    # Run all validations
make terraform-fmt  # Format Terraform files
```

## 🔄 Development Workflow

### 1. Local Development

```bash
# Setup
make setup
make local-up

# Create new migration
vim migrations/sql/V4__your_migration.sql

# Test migration
make local-migrate
make local-info

# Verify
make local-connect
```

### 2. Commit and Push

```bash
git add .
git commit -m "feat: add new migration"
git push origin feature-branch
```

### 3. Create Pull Request

- GitHub Actions runs automatically:
  - ✅ Terraform validate
  - ✅ SQL validation
  - ✅ Terraform plan (shows changes)

### 4. Review and Merge

- Review Terraform plan in PR comments
- Get approval
- Merge to main

### 5. Automatic Deployment

- GitHub Actions deploys to AWS
- Runs migrations on RDS
- Updates infrastructure

## 📊 Database Schema

### Core Tables

1. **customers** - Customer information
2. **vehicles** - Vehicle registry
3. **service_types** - Service catalog
4. **appointments** - Scheduled appointments
5. **service_records** - Service execution details
6. **parts_used** - Parts used in services

### Relationships

```
customers (1) ----< (N) vehicles
    |                      |
    |                      |
    +----< appointments >--+
              |
              |
         service_records
              |
              |
         parts_used
```

## 🔐 Security Features

### Local Environment
- Environment variables for credentials
- No hardcoded passwords
- Docker network isolation

### AWS Environment
- Encrypted storage (at rest)
- TLS/SSL (in transit)
- Security groups (network isolation)
- AWS Secrets Manager (password management)
- IAM roles (no access keys)
- OIDC authentication (GitHub Actions)

## 💰 Cost Breakdown

### AWS Resources (Monthly)

| Resource | Specification | Cost |
|----------|--------------|------|
| RDS MySQL | db.t4g.micro | ~$12 |
| Storage | 20GB gp3 | ~$2 |
| Backups | 7 days | ~$0.50 |
| **Total** | | **~$14.50** |

### Cost Optimization
- Stop RDS when not in use: **Save 40-50%**
- Use single-AZ: **Already optimized**
- Minimal backup retention: **Already optimized**
- No Performance Insights: **Already disabled**

## 🧪 Testing Strategy

### Local Testing
1. Docker Compose for development
2. Flyway migrations tested locally
3. SQL syntax validation

### CI/CD Testing
1. Terraform validation
2. SQL linting (sqlfluff)
3. Migration validation
4. Infrastructure plan review

### AWS Testing
1. Deploy to dev environment
2. Run migrations on RDS
3. Verify connectivity
4. Monitor CloudWatch logs

## 📚 Learning Resources

### Terraform
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

### Flyway
- [Flyway Documentation](https://flywaydb.org/documentation/)
- [Flyway Tutorials](https://flywaydb.org/documentation/tutorials/)

### MySQL
- [MySQL 8.4 Reference](https://dev.mysql.com/doc/refman/8.4/en/)
- [MySQL Performance Tuning](https://dev.mysql.com/doc/refman/8.4/en/optimization.html)

### AWS RDS
- [RDS Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)
- [RDS MySQL Guide](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html)

### GitHub Actions
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [AWS OIDC Guide](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)

## 🤝 Contributing

### Before Submitting PR
- [ ] Test locally with Docker Compose
- [ ] Follow SQL style guide
- [ ] Update documentation if needed
- [ ] Run `make ci-validate`
- [ ] Check Terraform format: `make terraform-fmt`

### PR Checklist
- [ ] Clear description of changes
- [ ] Migration files follow naming convention
- [ ] Tests pass locally
- [ ] CI/CD checks pass
- [ ] Documentation updated

## 🐛 Common Issues

### "Can't connect to MySQL"
```bash
# Check if running
docker-compose ps

# Check logs
docker-compose logs mysql

# Restart
docker-compose restart mysql
```

### "Terraform state locked"
```bash
# Check DynamoDB lock table
# Manually unlock (if safe)
cd terraform
terraform force-unlock LOCK_ID
```

### "Migration failed"
```bash
# Check migration history
make local-info

# Repair if needed
docker-compose run --rm flyway repair

# Re-run
make local-migrate
```

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/FIAP-SOAT-Net/fiap-soat-oficina-mecanica-infrastructure-database/issues)
- **Documentation**: See `docs/` directory
- **Team**: FIAP SOAT Team

---

**Last Updated**: November 2025
