# 🚀 Quick Reference Guide

Essential commands and information for daily use.

## ⚡ Most Used Commands

### Local Development
```bash
make local-up          # Start MySQL
make local-down        # Stop MySQL
make local-migrate     # Run migrations
make local-connect     # Connect to DB
make local-logs        # View logs
make local-info        # Migration status
```

### Terraform
```bash
make terraform-plan    # Preview changes
make terraform-apply   # Deploy to AWS
make terraform-output  # Show outputs
```

### RDS Management
```bash
make rds-status        # Check RDS status
make rds-password      # Get password
make rds-stop          # Stop (save money)
make rds-start         # Start
```

## 📝 File Locations

```
Important Files:
├── .env                    ← Local credentials
├── terraform/terraform.tfvars  ← AWS config
├── migrations/sql/         ← Add migrations here
└── README.md               ← Full documentation

Quick Access:
├── make help               ← All commands
├── make setup              ← Initial setup
└── ./scripts/setup.sh      ← Interactive setup
```

## 🔗 Connection Strings

### Local (Docker)
```bash
# MySQL CLI
mysql -h 127.0.0.1 -P 3306 -u workshop_user -p smart_workshop

# Docker exec
docker exec -it smart-workshop-db mysql -u workshop_user -p

# JDBC
jdbc:mysql://localhost:3306/smart_workshop
```

### AWS RDS
```bash
# Get endpoint
cd terraform && terraform output rds_endpoint

# Get password
make rds-password

# Connection command
make rds-connect
```

## 📊 Database Schema

### Tables
1. **customers** - Customer information
2. **vehicles** - Vehicle registry  
3. **service_types** - Service catalog (15 types)
4. **appointments** - Scheduled services
5. **service_records** - Service execution
6. **parts_used** - Parts in services

### Useful Queries
```sql
-- View all customers
SELECT * FROM customers;

-- Customer vehicles
SELECT c.name, v.license_plate, v.brand, v.model
FROM customers c
JOIN vehicles v ON c.id = v.customer_id;

-- Service types
SELECT * FROM service_types WHERE is_active = TRUE;

-- Recent appointments
SELECT * FROM appointments 
WHERE appointment_date >= CURDATE()
ORDER BY appointment_date;

-- Migration history
SELECT * FROM flyway_schema_history 
ORDER BY installed_rank;
```

## 🔧 Troubleshooting

### Can't connect to local MySQL?
```bash
docker-compose ps                 # Check status
docker-compose logs mysql         # Check logs
docker-compose restart mysql      # Restart
```

### Migration failed?
```bash
make local-info                   # Check status
docker-compose run --rm flyway repair  # Repair
make local-migrate                # Retry
```

### Terraform error?
```bash
cd terraform
terraform validate                # Check config
terraform fmt                     # Format files
terraform plan                    # Dry run
```

## 📚 Documentation Quick Links

- **Setup**: `README.md` → Quick Start
- **Migrations**: `docs/MIGRATION_GUIDE.md`
- **SQL Style**: `docs/SQL_STYLE_GUIDE.md`
- **CI/CD**: `docs/GITHUB_ACTIONS_SETUP.md`
- **Structure**: `docs/PROJECT_STRUCTURE.md`

## 🔐 GitHub Secrets Needed

For CI/CD to work, configure these in GitHub:

```
Required Secrets:
├── AWS_ROLE_ARN              # IAM Role for OIDC
├── VPC_ID                    # Your VPC ID
├── SUBNET_IDS                # ["subnet-xxx", "subnet-yyy"]
└── ALLOWED_CIDR_BLOCKS       # ["YOUR_IP/32"]

Optional Variables:
└── AWS_REGION                # Default: us-east-1
```

## 💰 Cost Tracking

### Monthly Costs
- RDS db.t4g.micro: **~$12**
- Storage 20GB gp3: **~$2**
- Backups 7 days: **~$0.50**
- **Total: ~$14.50/month**

### Save Money
```bash
# Stop RDS when not using
make rds-stop     # Saves ~50%

# Auto-starts after 7 days
# Remember to stop again!
```

## 🚦 Workflow

### Adding New Migration
```bash
# 1. Create migration file
vim migrations/sql/V4__your_change.sql

# 2. Test locally
make local-migrate
make local-info

# 3. Verify in database
make local-connect
SHOW TABLES;

# 4. Commit and push
git add migrations/sql/V4__your_change.sql
git commit -m "feat(db): add your change"
git push
```

### Deploying to AWS
```bash
# 1. Configure terraform.tfvars
vim terraform/terraform.tfvars

# 2. Plan
make terraform-plan

# 3. Apply (creates RDS)
make terraform-apply

# 4. Get credentials
make rds-password

# 5. Connect
make rds-connect
```

## ⚙️ Environment Variables

### Local (.env)
```bash
MYSQL_ROOT_PASSWORD=root_password
MYSQL_DATABASE=smart_workshop
MYSQL_USER=workshop_user
MYSQL_PASSWORD=workshop_password
MYSQL_PORT=3306
```

### AWS (terraform.tfvars)
```hcl
vpc_id = "vpc-xxxxxxxxx"
subnet_ids = ["subnet-xxx", "subnet-yyy"]
allowed_cidr_blocks = ["YOUR_IP/32"]
```

## 📞 Getting Help

1. Check `README.md` for detailed docs
2. Run `make help` for all commands
3. Check `docs/` for specific guides
4. Open GitHub Issue if stuck

## 🎯 Daily Developer Workflow

### Morning
```bash
make local-up          # Start database
make local-logs        # Check it's healthy
```

### Development
```bash
# Make changes to migrations/sql/
make local-migrate     # Apply changes
make local-connect     # Test manually
```

### Before Committing
```bash
make ci-validate       # Run all checks
git add .
git commit -m "feat: your change"
git push
```

### End of Day
```bash
make local-down        # Stop local DB
```

### AWS Deployment Day
```bash
make terraform-plan    # Review changes
make terraform-apply   # Deploy
make rds-status        # Verify
```

## 🔄 Common Patterns

### Full Reset (Local)
```bash
make local-clean       # ⚠️ Deletes all data
make local-up          # Restart fresh
make local-migrate     # Reapply migrations
```

### Check Everything
```bash
make local-info        # Migration status
make local-connect     # Manual check
make terraform-output  # AWS info
make rds-status        # RDS status
```

### Emergency Rollback
```bash
# Local: just restart
make local-clean && make local-up

# AWS: requires new migration
# Create V{N+1}__rollback_change.sql
```

## 📱 Quick Status Check

```bash
# Are services running?
docker-compose ps

# Are migrations current?
make local-info

# What's the RDS status?
make rds-status

# Any errors in logs?
make local-logs | grep -i error
```

## 🎓 Learning Resources

- [MySQL 8.4 Docs](https://dev.mysql.com/doc/refman/8.4/en/)
- [Terraform AWS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Flyway Docs](https://flywaydb.org/documentation/)
- [GitHub Actions](https://docs.github.com/en/actions)

---

**Pro Tip**: Add this to your shell aliases:
```bash
alias workshop-up='cd ~/path/to/project && make local-up'
alias workshop-connect='cd ~/path/to/project && make local-connect'
```

**Remember**: Always test locally before deploying to AWS! 🚀
