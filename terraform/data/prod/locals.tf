locals {
  environment = "prod"

  state_bucket      = "as-bank-terraform-state-${data.aws_caller_identity.current.account_id}"
  network_state_key = "network/prod/terraform.tfstate"

  instance_class          = "db.t4g.micro"
  multi_az                = false
  backup_retention_period = 7
  apply_immediately       = false
}
