ephemeral "aws_secretsmanager_random_password" "database" {
  for_each = local.services

  password_length     = 32
  exclude_punctuation = true
}

resource "aws_secretsmanager_secret" "database" {
  for_each = local.services

  #checkov:skip=CKV_AWS_149:The AWS-managed Secrets Manager key provides encryption without adding a persistent customer-managed KMS key to this learning environment.
  name        = "as-bank/${var.environment}/database/${each.value.service_name}"
  description = "${each.value.service_name} database connection credentials."

  recovery_window_in_days = 7

  tags = {
    Service = each.value.service_name
  }

  # Credentials must survive the normal RDS teardown/rebuild lifecycle.
  lifecycle {
    prevent_destroy = true
  }
}

ephemeral "aws_secretsmanager_secret_version" "existing" {
  for_each = {
    for service, config in local.services :
    service => config
    if(
      var.databases_enabled &&
      lookup(var.snapshot_identifiers, service, null) != null
    )
  }

  secret_id = aws_secretsmanager_secret.database[each.key].id
}

resource "aws_secretsmanager_secret_version" "database" {
  for_each = var.databases_enabled ? local.services : {}

  secret_id = aws_secretsmanager_secret.database[each.key].id

  secret_string_wo = jsonencode({
    host     = aws_db_instance.service[each.key].address
    port     = local.postgresql_port
    database = each.value.database_name
    username = each.value.username

    password = lookup(var.snapshot_identifiers, each.key, null) == null ? (
      ephemeral.aws_secretsmanager_random_password.database[each.key].random_password
      ) : (
      jsondecode(
        ephemeral.aws_secretsmanager_secret_version.existing[each.key].secret_string
      )["password"]
    )
  })

  secret_string_wo_version = var.database_password_version
}
