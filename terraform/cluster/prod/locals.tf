locals {
  environment = "prod"

  state_bucket        = "as-bank-terraform-state-${data.aws_caller_identity.current.account_id}"
  bootstrap_state_key = "bootstrap/terraform.tfstate"
  network_state_key   = "network/prod/terraform.tfstate"

  kubernetes_version = "1.35"

  bootstrap_instance_types = [
    "t3.medium",
  ]

  bootstrap_min_size     = 2
  bootstrap_desired_size = 2
  bootstrap_max_size     = 3

  karpenter_capacity_type       = "on-demand"
  karpenter_controller_replicas = 2
}
