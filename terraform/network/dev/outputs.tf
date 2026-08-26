output "vpc_id" {
  description = "VPC ID used by later Terraform layers."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs used by later Terraform layers."
  value       = module.network.public_subnet_ids
}

output "public_subnet_ids_by_az" {
  description = "Public subnet IDs keyed by availability zone."
  value       = module.network.public_subnet_ids_by_az
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by later Terraform layers."
  value       = module.network.private_subnet_ids
}

output "private_subnet_ids_by_az" {
  description = "Private subnet IDs keyed by availability zone."
  value       = module.network.private_subnet_ids_by_az
}

output "private_route_table_ids_by_az" {
  description = "Private route table IDs keyed by availability zone."
  value       = module.network.private_route_table_ids_by_az
}

output "availability_zones" {
  description = "Availability zones used by this environment."
  value       = module.network.availability_zones
}
