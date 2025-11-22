# Security Group for RDS
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-${var.environment}-rds-"
  description = "Security group for ${var.project_name} RDS instance"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    {
      Name = "${var.project_name}-${var.environment}-rds-sg"
    },
    var.additional_tags
  )
}

# Ingress rule for allowed CIDR blocks (your IP)
resource "aws_security_group_rule" "rds_ingress_cidr" {
  count = length(var.allowed_cidr_blocks) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = var.db_port
  to_port           = var.db_port
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.rds.id
  description       = "Allow MySQL access from specified CIDR blocks"
}

# Ingress rule for allowed security groups (EKS, etc)
resource "aws_security_group_rule" "rds_ingress_sg" {
  count = length(var.allowed_security_group_ids)

  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = var.allowed_security_group_ids[count.index]
  security_group_id        = aws_security_group.rds.id
  description              = "Allow MySQL access from security group ${var.allowed_security_group_ids[count.index]}"
}

# Egress rule (allow all outbound - standard practice)
resource "aws_security_group_rule" "rds_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound traffic"
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name_prefix = "${var.project_name}-${var.environment}-"
  subnet_ids  = var.subnet_ids
  description = "Subnet group for ${var.project_name} RDS instance"

  tags = merge(
    {
      Name = "${var.project_name}-${var.environment}-db-subnet-group"
    },
    var.additional_tags
  )
}

# DB Parameter Group
resource "aws_db_parameter_group" "main" {
  name_prefix = "${var.project_name}-${var.environment}-mysql84-"
  family      = "mysql8.4"
  description = "Custom parameter group for MySQL 8.4"

  # Performance and character set optimization
  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  parameter {
    name  = "max_connections"
    value = "200"
  }

  parameter {
    name  = "max_allowed_packet"
    value = "67108864" # 64MB
  }

  # Logging for troubleshooting
  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  parameter {
    name  = "log_queries_not_using_indexes"
    value = "1"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    {
      Name = "${var.project_name}-${var.environment}-mysql84-params"
    },
    var.additional_tags
  )
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier_prefix = "${var.project_name}-${var.environment}-"

  # Engine configuration
  engine               = "mysql"
  engine_version       = var.db_engine_version
  instance_class       = var.db_instance_class
  parameter_group_name = aws_db_parameter_group.main.name

  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  port     = var.db_port

  # Use AWS Secrets Manager for password management
  manage_master_user_password = true

  # Storage configuration
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = var.db_storage_type
  storage_encrypted     = true # Always encrypt at rest

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = var.publicly_accessible

  # High availability
  multi_az = var.multi_az

  # Backup configuration
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  copy_tags_to_snapshot   = true

  # Snapshot configuration
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-${var.environment}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Deletion protection
  deletion_protection = var.deletion_protection

  # Monitoring
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  performance_insights_enabled    = var.performance_insights_enabled
  monitoring_interval             = 60 # Enhanced monitoring every 60 seconds
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn

  # Updates
  auto_minor_version_upgrade = true
  apply_immediately          = var.environment == "dev" ? true : false

  lifecycle {
    ignore_changes = [
      password, # Managed by Secrets Manager
      final_snapshot_identifier,
    ]
  }

  tags = merge(
    {
      Name = "${var.project_name}-${var.environment}-rds"
    },
    var.additional_tags
  )
}

# IAM Role for Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name_prefix = "${var.project_name}-${var.environment}-rds-monitoring-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    {
      Name = "${var.project_name}-${var.environment}-rds-monitoring-role"
    },
    var.additional_tags
  )
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
