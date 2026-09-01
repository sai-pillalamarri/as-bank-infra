resource "aws_iam_role" "aws_load_balancer_controller" {
  name = "${local.cluster_name}-aws-load-balancer-controller"

  assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role.json
}

resource "aws_iam_role_policy" "aws_load_balancer_controller" {
  name = "load-balancer-controller"
  role = aws_iam_role.aws_load_balancer_controller.name

  # Keep this aligned with the controller version installed by the runtime module.
  policy = file("${path.module}/aws-load-balancer-controller-iam-policy.json")
}

resource "aws_eks_pod_identity_association" "aws_load_balancer_controller" {
  cluster_name    = aws_eks_cluster.this.name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.aws_load_balancer_controller.arn

  depends_on = [
    aws_iam_role_policy.aws_load_balancer_controller,
  ]
}

resource "aws_iam_role" "external_dns" {
  name = "${local.cluster_name}-external-dns"

  assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role.json
}

resource "aws_iam_role_policy" "external_dns" {
  name   = "route53-sync"
  role   = aws_iam_role.external_dns.name
  policy = data.aws_iam_policy_document.external_dns.json
}

resource "aws_eks_pod_identity_association" "external_dns" {
  cluster_name    = aws_eks_cluster.this.name
  namespace       = "external-dns"
  service_account = "external-dns"
  role_arn        = aws_iam_role.external_dns.arn

  depends_on = [
    aws_iam_role_policy.external_dns,
  ]
}
