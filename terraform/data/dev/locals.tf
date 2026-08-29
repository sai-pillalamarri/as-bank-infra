locals {
  environment = "dev"

  state_bucket      = "as-bank-terraform-state-${data.aws_caller_identity.current.account_id}"
  network_state_key = "network/dev/terraform.tfstate"

  instance_class          = "db.t4g.micro"
  multi_az                = false
  backup_retention_period = 1
  apply_immediately       = true
}
