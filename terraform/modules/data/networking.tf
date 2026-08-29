resource "aws_db_subnet_group" "this" {
  count = var.databases_enabled ? 1 : 0

  name       = "as-bank-${var.environment}"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "as-bank-${var.environment}"
  }
}

resource "aws_security_group" "database" {
  count = var.databases_enabled ? 1 : 0

  #checkov:skip=CKV2_AWS_5:The security group is attached to every RDS instance through vpc_security_group_ids; Checkov cannot resolve the conditional module relationship.
  name        = "as-bank-${var.environment}-database"
  description = "PostgreSQL access for AS Bank service databases."
  vpc_id      = var.vpc_id

  tags = {
    Name = "as-bank-${var.environment}-database"
  }
}

resource "aws_vpc_security_group_ingress_rule" "postgresql" {
  for_each = var.databases_enabled ? var.private_subnet_cidrs : toset([])

  security_group_id = aws_security_group.database[0].id
  description       = "PostgreSQL from an application private subnet."

  cidr_ipv4   = each.value
  from_port   = local.postgresql_port
  to_port     = local.postgresql_port
  ip_protocol = "tcp"
}
