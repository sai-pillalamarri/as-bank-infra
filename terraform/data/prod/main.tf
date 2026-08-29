module "data" {
  source = "../../modules/data"

  environment = local.environment

  vpc_id             = data.terraform_remote_state.network.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids

  private_subnet_cidrs = toset([
    for subnet in data.aws_subnet.private :
    subnet.cidr_block
  ])

  instance_class          = local.instance_class
  multi_az                = local.multi_az
  backup_retention_period = local.backup_retention_period
  apply_immediately       = local.apply_immediately

  databases_enabled         = var.databases_enabled
  snapshot_identifiers      = var.snapshot_identifiers
  database_password_version = var.database_password_version
  final_snapshot_suffix     = var.final_snapshot_suffix
}
