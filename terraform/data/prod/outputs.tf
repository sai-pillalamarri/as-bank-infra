output "databases" {
  description = "Prod service database connection metadata."
  value       = module.data.databases
}

output "database_secret_arns" {
  description = "Prod database credential secret ARNs."
  value       = module.data.database_secret_arns
}

output "database_security_group_id" {
  description = "Security group protecting the running prod databases."
  value       = module.data.database_security_group_id
}
