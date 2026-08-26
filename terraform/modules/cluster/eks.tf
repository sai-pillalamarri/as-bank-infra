resource "aws_cloudwatch_log_group" "eks" {
  #checkov:skip=CKV_AWS_158:CloudWatch Logs already encrypts log data at rest; a customer-managed KMS key is not required here.
  #checkov:skip=CKV_AWS_338:EKS is ephemeral and seven days covers Stage 4 troubleshooting without retaining a year of paid logs.

  name              = "/aws/eks/${local.cluster_name}/cluster"
  retention_in_days = 7
}

resource "aws_eks_cluster" "this" {

  #checkov:skip=CKV_AWS_39:GitHub-hosted runners and the MFA operator need API reachability; private endpoint access remains enabled.
  #checkov:skip=CKV_AWS_38:GitHub-hosted runner addresses are not stable enough for a fixed CIDR allowlist; API access still requires an authorized IAM principal.
  #checkov:skip=CKV_AWS_58:EKS 1.35 provides default KMS envelope encryption for Kubernetes API data.

  name     = local.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.kubernetes_version

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = false
  }

  vpc_config {
    subnet_ids = values(var.private_subnet_ids_by_az)

    endpoint_private_access = true
    endpoint_public_access  = true

    # The operator works outside the VPC. Authentication still requires an authorized IAM principal.
    public_access_cidrs = ["0.0.0.0/0"]
  }

  depends_on = [
    aws_cloudwatch_log_group.eks,
    aws_iam_role_policy_attachment.eks_cluster,
  ]
}

resource "aws_eks_access_entry" "operator" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.operator_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "operator_admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.operator_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [
    aws_eks_access_entry.operator,
  ]
}

resource "aws_eks_access_entry" "automation" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.automation_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "automation_admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.automation_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [
    aws_eks_access_entry.automation,
  ]
}

resource "aws_eks_access_entry" "plan" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.plan_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "plan_view" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.plan_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminViewPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [
    aws_eks_access_entry.plan,
  ]
}
