output "databases" {
  description = "Connection metadata for running service databases."
  value = {
    for service, database in aws_db_instance.service :
    service => {
      address       = database.address
      port          = database.port
      database_name = local.services[service].database_name
      secret_arn    = aws_secretsmanager_secret.database[service].arn
    }
  }
}

output "database_secret_arns" {
  description = "Database connection secret ARNs keyed by service."
  value = {
    for service, secret in aws_secretsmanager_secret.database :
    service => secret.arn
  }
}

output "database_security_group_id" {
  description = "Security group protecting the running RDS instances."
  value       = var.databases_enabled ? aws_security_group.database[0].id : null
}
