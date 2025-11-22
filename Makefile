# Makefile for Smart Mechanical Workshop Database Infrastructure

.PHONY: help local-up local-down local-migrate local-clean terraform-init terraform-plan terraform-apply terraform-destroy check-env

# Default target
.DEFAULT_GOAL := help

##@ General

help: ## Display this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Local Development

local-up: ## Start local MySQL database
	@echo "🚀 Starting local MySQL database..."
	docker-compose up -d mysql
	@echo "⏳ Waiting for MySQL to be ready..."
	@sleep 10
	@echo "✅ MySQL is ready!"
	@echo "📊 Connection info:"
	@echo "   Host: localhost"
	@echo "   Port: 3306"
	@echo "   Database: smart_workshop"
	@echo "   User: workshop_user"
	@echo "   Password: (check .env file)"

local-down: ## Stop local MySQL database
	@echo "🛑 Stopping local MySQL database..."
	docker-compose down
	@echo "✅ Stopped!"

local-migrate: ## Run Flyway migrations locally
	@echo "🔄 Running database migrations..."
	docker-compose run --rm flyway migrate
	@echo "✅ Migrations completed!"
	@echo "📋 Migration status:"
	@make local-info

local-info: ## Show migration status
	@echo "📋 Migration history:"
	docker-compose run --rm flyway info

local-validate: ## Validate migrations
	@echo "🔍 Validating migrations..."
	docker-compose run --rm flyway validate
	@echo "✅ Validation passed!"

local-clean: ## Stop and remove all local data (⚠️  DESTRUCTIVE)
	@echo "⚠️  WARNING: This will delete all local database data!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose down -v; \
		echo "✅ Cleaned up!"; \
	else \
		echo "❌ Cancelled"; \
	fi

local-connect: ## Connect to local MySQL using CLI
	@echo "🔌 Connecting to local MySQL..."
	docker exec -it smart-workshop-db mysql -u workshop_user -p smart_workshop

local-logs: ## View local MySQL logs
	docker-compose logs -f mysql

##@ Terraform AWS

check-env: ## Check if required environment variables are set
	@echo "🔍 Checking environment..."
	@if [ -z "$$AWS_REGION" ]; then echo "⚠️  AWS_REGION not set, using us-east-1"; fi
	@if [ ! -f terraform/terraform.tfvars ]; then \
		echo "❌ terraform/terraform.tfvars not found!"; \
		echo "📝 Copy terraform/terraform.tfvars.example and fill in your values"; \
		exit 1; \
	fi
	@echo "✅ Environment ready!"

terraform-init: check-env ## Initialize Terraform
	@echo "🔧 Initializing Terraform..."
	cd terraform && terraform init
	@echo "✅ Initialized!"

terraform-validate: ## Validate Terraform configuration
	@echo "🔍 Validating Terraform..."
	cd terraform && terraform fmt -check -recursive || (echo "❌ Run 'make terraform-fmt' to fix formatting" && exit 1)
	cd terraform && terraform validate
	@echo "✅ Validation passed!"

terraform-fmt: ## Format Terraform files
	@echo "📝 Formatting Terraform files..."
	cd terraform && terraform fmt -recursive
	@echo "✅ Formatted!"

terraform-plan: terraform-init ## Show Terraform execution plan
	@echo "📋 Planning Terraform changes..."
	cd terraform && terraform plan
	@echo "✅ Plan complete!"

terraform-apply: terraform-init ## Apply Terraform changes (deploy to AWS)
	@echo "🚀 Applying Terraform changes..."
	@echo "⚠️  This will create resources in AWS (will cost money)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		cd terraform && terraform apply; \
		echo "✅ Deployment complete!"; \
		echo "📊 RDS Endpoint:"; \
		cd terraform && terraform output rds_endpoint; \
		echo "🔑 Get password from AWS Secrets Manager:"; \
		cd terraform && terraform output db_password_secret_arn; \
	else \
		echo "❌ Cancelled"; \
	fi

terraform-destroy: terraform-init ## Destroy all Terraform resources (⚠️  DESTRUCTIVE)
	@echo "⚠️  WARNING: This will destroy all AWS resources!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		cd terraform && terraform destroy; \
		echo "✅ Resources destroyed!"; \
	else \
		echo "❌ Cancelled"; \
	fi

terraform-output: ## Show Terraform outputs
	@echo "📊 Terraform outputs:"
	cd terraform && terraform output

terraform-state: ## Show Terraform state
	@echo "📋 Terraform state:"
	cd terraform && terraform state list

##@ AWS RDS Management

rds-start: ## Start RDS instance (if stopped)
	@echo "▶️  Starting RDS instance..."
	@DB_ID=$$(cd terraform && terraform output -raw rds_instance_id 2>/dev/null); \
	if [ -z "$$DB_ID" ]; then \
		echo "❌ No RDS instance found. Run 'make terraform-apply' first."; \
		exit 1; \
	fi; \
	aws rds start-db-instance --db-instance-identifier $$DB_ID
	@echo "✅ RDS instance starting..."

rds-stop: ## Stop RDS instance (to save costs)
	@echo "⏸️  Stopping RDS instance..."
	@DB_ID=$$(cd terraform && terraform output -raw rds_instance_id 2>/dev/null); \
	if [ -z "$$DB_ID" ]; then \
		echo "❌ No RDS instance found."; \
		exit 1; \
	fi; \
	aws rds stop-db-instance --db-instance-identifier $$DB_ID
	@echo "✅ RDS instance stopping... (will auto-start after 7 days)"

rds-status: ## Check RDS instance status
	@echo "📊 RDS Status:"
	@DB_ID=$$(cd terraform && terraform output -raw rds_instance_id 2>/dev/null); \
	if [ -z "$$DB_ID" ]; then \
		echo "❌ No RDS instance found."; \
		exit 1; \
	fi; \
	aws rds describe-db-instances \
		--db-instance-identifier $$DB_ID \
		--query 'DBInstances[0].[DBInstanceStatus,Endpoint.Address,Endpoint.Port]' \
		--output table

rds-password: ## Get RDS password from Secrets Manager
	@echo "🔑 Getting RDS password..."
	@SECRET_ARN=$$(cd terraform && terraform output -raw db_password_secret_arn 2>/dev/null); \
	if [ -z "$$SECRET_ARN" ]; then \
		echo "❌ No secret found."; \
		exit 1; \
	fi; \
	aws secretsmanager get-secret-value \
		--secret-id $$SECRET_ARN \
		--query SecretString \
		--output text | jq -r .password

rds-connect: ## Show command to connect to RDS
	@echo "🔌 RDS Connection Command:"
	@cd terraform && terraform output -raw mysql_cli_command 2>/dev/null || echo "❌ No RDS instance found"

##@ CI/CD

ci-validate: ## Run all validations (like CI pipeline)
	@echo "🔍 Running all validations..."
	@make terraform-validate
	@make local-validate
	@echo "✅ All validations passed!"

##@ Utility

clean-all: local-clean ## Clean everything (local + terraform)
	@echo "🧹 Cleaning all resources..."
	@echo "This will clean local Docker resources only."
	@echo "To destroy AWS resources, run 'make terraform-destroy'"

install-tools: ## Install required tools (macOS with Homebrew)
	@echo "🔧 Installing required tools..."
	@if ! command -v brew &> /dev/null; then \
		echo "❌ Homebrew not found. Install from https://brew.sh"; \
		exit 1; \
	fi
	brew install terraform
	brew install mysql-client
	brew install flyway
	brew install awscli
	@echo "✅ Tools installed!"

setup: ## Initial setup (copy config files)
	@echo "🔧 Setting up project..."
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "✅ Created .env file - please edit with your values"; \
	else \
		echo "⚠️  .env already exists, skipping"; \
	fi
	@if [ ! -f flyway.conf ]; then \
		cp flyway.conf.example flyway.conf; \
		echo "✅ Created flyway.conf file - please edit with your values"; \
	else \
		echo "⚠️  flyway.conf already exists, skipping"; \
	fi
	@if [ ! -f terraform/terraform.tfvars ]; then \
		cp terraform/terraform.tfvars.example terraform/terraform.tfvars; \
		echo "✅ Created terraform.tfvars - please edit with your values"; \
	else \
		echo "⚠️  terraform.tfvars already exists, skipping"; \
	fi
	@echo "📝 Next steps:"
	@echo "   1. Edit .env with local database credentials"
	@echo "   2. Edit terraform/terraform.tfvars with AWS configuration"
	@echo "   3. Run 'make local-up' to start local development"
	@echo "   4. Run 'make terraform-plan' to preview AWS deployment"
