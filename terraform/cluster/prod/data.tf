data "aws_caller_identity" "current" {}

data "terraform_remote_state" "bootstrap" {
  backend = "s3"

  config = {
    bucket = local.state_bucket
    key    = local.bootstrap_state_key
    region = var.aws_region
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = local.state_bucket
    key    = local.network_state_key
    region = var.aws_region
  }
}
