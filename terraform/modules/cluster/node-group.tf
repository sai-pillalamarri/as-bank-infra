resource "aws_eks_node_group" "bootstrap" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.cluster_name}-bootstrap"

  node_role_arn = aws_iam_role.bootstrap_node.arn
  subnet_ids    = values(var.private_subnet_ids_by_az)

  version       = var.kubernetes_version
  ami_type      = "AL2023_x86_64_STANDARD"
  capacity_type = "ON_DEMAND"

  instance_types = var.bootstrap_instance_types

  scaling_config {
    min_size     = var.bootstrap_min_size
    desired_size = var.bootstrap_desired_size
    max_size     = var.bootstrap_max_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    "as-bank.io/node-purpose" = "system"
  }

  # The node role and networking must exist before EKS can successfully register instances.
  depends_on = [
    aws_iam_role_policy_attachment.bootstrap_worker,
    aws_iam_role_policy_attachment.bootstrap_ecr,
    aws_eks_addon.pod_identity_agent,
    aws_eks_addon.vpc_cni,
  ]
}
