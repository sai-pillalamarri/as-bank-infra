module "cluster" {
  source = "../../modules/cluster"

  environment        = local.environment
  kubernetes_version = local.kubernetes_version

  operator_role_arn   = data.terraform_remote_state.bootstrap.outputs.operator_role_arn
  automation_role_arn = data.terraform_remote_state.bootstrap.outputs.infrastructure_environment_apply_role_arns[local.environment]
  plan_role_arn       = data.terraform_remote_state.bootstrap.outputs.infrastructure_environment_plan_role_arns[local.environment]

  vpc_id = data.terraform_remote_state.network.outputs.vpc_id

  public_subnet_ids_by_az = data.terraform_remote_state.network.outputs.public_subnet_ids_by_az

  private_subnet_ids_by_az = data.terraform_remote_state.network.outputs.private_subnet_ids_by_az

  private_route_table_ids_by_az = data.terraform_remote_state.network.outputs.private_route_table_ids_by_az

  bootstrap_instance_types = local.bootstrap_instance_types
  bootstrap_min_size       = local.bootstrap_min_size
  bootstrap_desired_size   = local.bootstrap_desired_size
  bootstrap_max_size       = local.bootstrap_max_size
}

module "karpenter_runtime" {
  count = var.install_karpenter ? 1 : 0

  source = "../../modules/karpenter-runtime"

  # Karpenter must clean its AWS resources before the cluster IAM and EKS resources disappear.
  depends_on = [
    module.cluster,
  ]

  providers = {
    helm = helm
  }

  environment               = local.environment
  cluster_name              = module.cluster.cluster_name
  interruption_queue_name   = module.cluster.karpenter_interruption_queue_name
  node_role_name            = module.cluster.karpenter_node_role_name
  cluster_security_group_id = module.cluster.cluster_security_group_id

  capacity_type       = local.karpenter_capacity_type
  controller_replicas = local.karpenter_controller_replicas
}

module "external_secrets_runtime" {
  count = var.install_external_secrets ? 1 : 0

  source = "../../modules/external-secrets-runtime"

  # Helm needs the cluster API before it can install the operator and CRDs.
  depends_on = [
    module.cluster,
  ]

  providers = {
    helm = helm
  }
}

module "kyverno_runtime" {
  count = var.install_kyverno ? 1 : 0

  source = "../../modules/kyverno-runtime"

  # Kyverno uses the Kubernetes API, so it belongs in the second cluster apply.
  depends_on = [
    module.cluster,
  ]

  providers = {
    helm = helm
  }
}

module "argocd_runtime" {
  count = var.install_argocd ? 1 : 0

  source = "../../modules/argocd-runtime"

  # Helm needs a reachable Kubernetes API, so this belongs in the second cluster apply.
  depends_on = [
    module.cluster,
    module.external_secrets_runtime,
    module.kyverno_runtime,
  ]

  providers = {
    helm = helm
  }

  environment           = local.environment
  gitops_repository_url = "https://github.com/sai-pillalamarri/as-bank-gitops.git"
  gitops_revision       = "main"
  ecr_registry = split(
    "/",
    data.terraform_remote_state.bootstrap.outputs.ecr_repository_urls["frontend"]
  )[0]
}
