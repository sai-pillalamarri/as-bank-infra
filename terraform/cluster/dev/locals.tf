locals {
  environment = "dev"

  state_bucket        = "as-bank-terraform-state-${data.aws_caller_identity.current.account_id}"
  bootstrap_state_key = "bootstrap/terraform.tfstate"
  network_state_key   = "network/dev/terraform.tfstate"

  kubernetes_version = "1.35"

  bootstrap_instance_types = [
    "t3.medium",
  ]

  bootstrap_min_size     = 1
  bootstrap_desired_size = 1
  bootstrap_max_size     = 2

  karpenter_capacity_type       = "spot"
  karpenter_controller_replicas = 1
}
