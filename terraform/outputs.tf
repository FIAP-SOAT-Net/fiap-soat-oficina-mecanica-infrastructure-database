# RDS endpoint
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "RDS instance address (hostname)"
  value       = aws_db_instance.main.address
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

# Database information
output "database_name" {
  description = "Name of the database"
  value       = aws_db_instance.main.db_name
}

output "database_username" {
  description = "Master username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

# Connection string
output "connection_string" {
  description = "JDBC connection string"
  value       = "jdbc:mysql://${aws_db_instance.main.endpoint}/${aws_db_instance.main.db_name}"
}

# Security
output "security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}

# Resource identifiers
output "rds_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.main.id
}

output "rds_resource_id" {
  description = "RDS instance resource ID"
  value       = aws_db_instance.main.resource_id
}

output "rds_arn" {
  description = "ARN of the RDS instance"
  value       = aws_db_instance.main.arn
}

# Quick connection command
output "mysql_cli_command" {
  description = "MySQL CLI connection command (password needed separately)"
  value       = "mysql -h ${aws_db_instance.main.address} -P ${aws_db_instance.main.port} -u ${aws_db_instance.main.username} -p ${aws_db_instance.main.db_name}"
}
