output "databases" {
  description = "Dev service database connection metadata."
  value       = module.data.databases
}

output "database_secret_arns" {
  description = "Dev database credential secret ARNs."
  value       = module.data.database_secret_arns
}

output "database_security_group_id" {
  description = "Security group protecting the running dev databases."
  value       = module.data.database_security_group_id
}
