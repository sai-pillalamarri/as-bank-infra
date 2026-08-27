resource "aws_iam_role" "eks_cluster" {
  name = "${local.cluster_name}-cluster"

  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "bootstrap_node" {
  name = "${local.cluster_name}-bootstrap-node"

  assume_role_policy = data.aws_iam_policy_document.node_assume_role.json
}

resource "aws_iam_role_policy_attachment" "bootstrap_worker" {
  role       = aws_iam_role.bootstrap_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "bootstrap_ecr" {
  role       = aws_iam_role.bootstrap_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

resource "aws_iam_role" "vpc_cni" {
  name = "${local.cluster_name}-vpc-cni"

  assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role.json
}

resource "aws_iam_role_policy_attachment" "vpc_cni" {
  role       = aws_iam_role.vpc_cni.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role" "ebs_csi" {
  name = "${local.cluster_name}-ebs-csi"

  assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_iam_role" "external_secrets" {
  name = "${local.cluster_name}-external-secrets"

  assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role.json
}

resource "aws_iam_role_policy" "external_secrets" {
  name   = "secrets-manager-read"
  role   = aws_iam_role.external_secrets.name
  policy = data.aws_iam_policy_document.external_secrets.json
}

resource "aws_iam_role" "kyverno" {
  name = "${local.cluster_name}-kyverno"

  assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role.json
}

resource "aws_iam_role_policy" "kyverno_ecr" {
  name   = "ecr-signature-read"
  role   = aws_iam_role.kyverno.name
  policy = data.aws_iam_policy_document.kyverno_ecr.json
}
