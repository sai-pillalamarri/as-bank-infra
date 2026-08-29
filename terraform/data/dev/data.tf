data "aws_caller_identity" "current" {}

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = local.state_bucket
    key    = local.network_state_key
    region = var.aws_region
  }
}

data "aws_subnet" "private" {
  for_each = toset(data.terraform_remote_state.network.outputs.private_subnet_ids)

  id = each.value
}
