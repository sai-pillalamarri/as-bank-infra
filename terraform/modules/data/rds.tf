resource "aws_db_instance" "service" {
  for_each = var.databases_enabled ? local.services : {}

  #checkov:skip=CKV_AWS_118:Enhanced Monitoring adds another IAM role and monitoring cost; Stage 8 provides the project's observability stack.
  #checkov:skip=CKV_AWS_157:Both environments stay Single-AZ while this project operates under its AWS Free Tier and credit budget.
  #checkov:skip=CKV_AWS_161:Applications use credentials from Secrets Manager; IAM database authentication is not part of the canonical application design.
  #checkov:skip=CKV_AWS_293:Deletion protection conflicts with the required snapshot-and-teardown lifecycle.
  #checkov:skip=CKV_AWS_353:Performance Insights is deferred to the observability stage rather than adding cost to the Stage 7 database baseline.

  identifier = "as-bank-${var.environment}-${each.key}"

  allocated_storage = local.allocated_storage_gib
  storage_type      = "gp3"
  storage_encrypted = true

  engine                   = "postgres"
  engine_version           = "16"
  engine_lifecycle_support = "open-source-rds-extended-support-disabled"
  instance_class           = var.instance_class

  snapshot_identifier = lookup(
    var.snapshot_identifiers,
    each.key,
    null
  )

  db_name = lookup(var.snapshot_identifiers, each.key, null) == null ? (
    each.value.database_name
  ) : null

  username = lookup(var.snapshot_identifiers, each.key, null) == null ? (
    each.value.username
  ) : null

  password_wo = lookup(var.snapshot_identifiers, each.key, null) == null ? (
    ephemeral.aws_secretsmanager_random_password.database[each.key].random_password
  ) : null

  password_wo_version = lookup(var.snapshot_identifiers, each.key, null) == null ? (
    var.database_password_version
  ) : null

  db_subnet_group_name   = aws_db_subnet_group.this[0].name
  vpc_security_group_ids = [aws_security_group.database[0].id]

  port                = local.postgresql_port
  publicly_accessible = false
  multi_az            = var.multi_az

  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-03:30"
  maintenance_window      = "sun:04:00-sun:04:30"

  auto_minor_version_upgrade = true
  apply_immediately          = var.apply_immediately

  enabled_cloudwatch_logs_exports = [
    "postgresql",
  ]

  iam_database_authentication_enabled = false
  performance_insights_enabled        = false
  deletion_protection                 = false

  copy_tags_to_snapshot     = true
  delete_automated_backups  = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "as-bank-${var.environment}-${each.key}-final-${var.final_snapshot_suffix}"

  tags = {
    Name    = "as-bank-${var.environment}-${each.key}"
    Service = each.value.service_name
  }

  lifecycle {
    # A snapshot is only the creation source. Changing the input later must not replace a running database.
    ignore_changes = [
      snapshot_identifier,
    ]
  }

}
