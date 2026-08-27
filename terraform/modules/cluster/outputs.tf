output "nat_gateway_ids" {
  description = "NAT gateways created while the cluster layer is active."
  value = {
    for availability_zone, nat_gateway in aws_nat_gateway.this :
    availability_zone => nat_gateway.id
  }
}

output "interface_endpoint_ids" {
  description = "Paid interface endpoints created with the cluster layer."
  value = {
    for service, endpoint in aws_vpc_endpoint.interface :
    service => endpoint.id
  }
}

output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint for the EKS cluster."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_security_group_id" {
  description = "Security group created by EKS for the cluster."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "bootstrap_node_group_name" {
  description = "Managed node group that runs cluster system workloads."
  value       = aws_eks_node_group.bootstrap.node_group_name
}

output "karpenter_controller_role_arn" {
  description = "IAM role used by the Karpenter controller through Pod Identity."
  value       = aws_iam_role.karpenter_controller.arn
}

output "karpenter_node_role_name" {
  description = "IAM role name used by EC2 nodes provisioned by Karpenter."
  value       = aws_iam_role.karpenter_node.name
}

output "karpenter_interruption_queue_name" {
  description = "SQS queue consumed by Karpenter for interruption handling."
  value       = aws_sqs_queue.karpenter.name
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded CA certificate used to verify the Kubernetes API."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "external_secrets_role_arn" {
  description = "IAM role used by External Secrets through EKS Pod Identity."
  value       = aws_iam_role.external_secrets.arn
}

output "kyverno_role_arn" {
  description = "IAM role used by the Kyverno admission controller through EKS Pod Identity."
  value       = aws_iam_role.kyverno.arn
}
