output "nat_gateway_ids" {
  description = "NAT gateways active with this cluster layer."
  value       = module.cluster.nat_gateway_ids
}

output "interface_endpoint_ids" {
  description = "Paid AWS service endpoints active with this cluster layer."
  value       = module.cluster.interface_endpoint_ids
}
output "cluster_name" {
  description = "EKS cluster name."
  value       = module.cluster.cluster_name
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint."
  value       = module.cluster.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "EKS cluster security group ID."
  value       = module.cluster.cluster_security_group_id
}

output "bootstrap_node_group_name" {
  description = "Managed bootstrap node group name."
  value       = module.cluster.bootstrap_node_group_name
}
