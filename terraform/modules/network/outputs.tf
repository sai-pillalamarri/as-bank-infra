output "vpc_id" {
  description = "VPC ID used by later Terraform layers."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs used by later Terraform layers."
  value       = values(aws_subnet.public)[*].id
}

output "public_subnet_ids_by_az" {
  description = "Public subnet IDs keyed by availability zone."
  value = {
    for availability_zone, subnet in aws_subnet.public :
    availability_zone => subnet.id
  }
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by later Terraform layers."
  value       = values(aws_subnet.private)[*].id
}

output "private_subnet_ids_by_az" {
  description = "Private subnet IDs keyed by availability zone."
  value = {
    for availability_zone, subnet in aws_subnet.private :
    availability_zone => subnet.id
  }
}

output "private_route_table_ids_by_az" {
  description = "Private route table IDs keyed by availability zone."
  value = {
    for availability_zone, route_table in aws_route_table.private :
    availability_zone => route_table.id
  }
}

output "availability_zones" {
  description = "Availability zones selected for this environment."
  value       = local.availability_zones
}
