resource "aws_eks_pod_identity_association" "kyverno" {
  cluster_name    = aws_eks_cluster.this.name
  namespace       = "kyverno"
  service_account = "kyverno-admission-controller"
  role_arn        = aws_iam_role.kyverno.arn

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_iam_role_policy.kyverno_ecr,
  ]
}
