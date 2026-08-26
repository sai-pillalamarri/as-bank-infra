resource "helm_release" "karpenter" {
  name       = "karpenter"
  namespace  = "kube-system"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "1.14.1"

  wait    = true
  timeout = 600

  set = [
    {
      name  = "serviceAccount.name"
      value = "karpenter"
    },
    {
      name  = "settings.clusterName"
      value = var.cluster_name
    },
    {
      name  = "settings.interruptionQueue"
      value = var.interruption_queue_name
    },
    {
      name  = "replicas"
      value = tostring(var.controller_replicas)
    },
  ]
}

resource "helm_release" "karpenter_config" {
  name      = "as-bank-karpenter-config"
  namespace = "kube-system"
  chart     = "${path.module}/config"

  wait    = true
  timeout = 300

  set = [
    {
      name  = "clusterName"
      value = var.cluster_name
    },
    {
      name  = "nodeRoleName"
      value = var.node_role_name
    },
    {
      name  = "clusterSecurityGroupId"
      value = var.cluster_security_group_id
    },
    {
      name  = "capacityType"
      value = var.capacity_type
    },
    {
      name  = "environment"
      value = var.environment
    },
  ]

  depends_on = [
    helm_release.karpenter,
  ]
}
