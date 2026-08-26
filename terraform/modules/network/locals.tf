locals {
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
  cluster_name       = "as-bank-${var.environment}"
}
