locals {
  cluster_name       = "as-bank-${var.environment}"
  availability_zones = sort(keys(var.public_subnet_ids_by_az))
  primary_az         = local.availability_zones[0]

  # Dev pays for one NAT. Prod keeps one per AZ so an AZ failure does not remove all egress.
  nat_availability_zones = var.environment == "prod" ? toset(local.availability_zones) : toset([
    local.primary_az,
  ])

  interface_endpoint_services = toset([
    "ecr.api",
    "ecr.dkr",
    "sts",
    "secretsmanager",
    "logs",
  ])
}
