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
