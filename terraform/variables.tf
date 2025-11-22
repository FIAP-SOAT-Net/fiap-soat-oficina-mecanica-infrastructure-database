# AWS Region
variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

# Environment
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Project name
variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "smart-workshop"
}

# Database configuration
variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "smart_workshop"
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "admin"
}

variable "db_port" {
  description = "Port on which the DB accepts connections"
  type        = number
  default     = 3306
}

# RDS Instance configuration
variable "db_instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
  default     = "db.t4g.micro" # ~$12/month - cheapest option with good performance
}

variable "db_allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = number
  default     = 20 # Minimum for gp3
}

variable "db_max_allocated_storage" {
  description = "Maximum storage for autoscaling (0 to disable)"
  type        = number
  default     = 50 # Allow growth if needed
}

variable "db_storage_type" {
  description = "Storage type (gp3, gp2, io1)"
  type        = string
  default     = "gp3" # Better performance/cost than gp2
}

variable "db_engine_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.4.0"
}

# Network configuration
variable "vpc_id" {
  description = "VPC ID where RDS will be deployed"
  type        = string
  # Must be provided via tfvars or environment variable
}

variable "subnet_ids" {
  description = "List of subnet IDs for RDS subnet group"
  type        = list(string)
  # Must be provided via tfvars or environment variable
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to the database"
  type        = list(string)
  default     = [] # Must be explicitly set for security
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect to the database (e.g., EKS)"
  type        = list(string)
  default     = []
}

# Backup configuration
variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 1 # Minimum recommended
}

variable "backup_window" {
  description = "Preferred backup window (UTC)"
  type        = string
  default     = "03:00-04:00" # 3 AM UTC (midnight São Paulo)
}

variable "maintenance_window" {
  description = "Preferred maintenance window (UTC)"
  type        = string
  default     = "mon:04:00-mon:05:00"
}

# High availability
variable "multi_az" {
  description = "Enable Multi-AZ deployment (higher cost)"
  type        = bool
  default     = false # Single AZ for dev to save costs
}

# Public access
variable "publicly_accessible" {
  description = "Allow public access to the database"
  type        = bool
  default     = true # Set to true for dev environment
}

# Monitoring
variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = ["error", "general", "slowquery"]
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false # Additional cost, disable for dev
}

# Deletion protection
variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false # Allow deletion in dev
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when destroying"
  type        = bool
  default     = true # Skip for dev to allow easy teardown
}

# Tags
variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
