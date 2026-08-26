resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoint_services

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = values(var.private_subnet_ids_by_az)

  security_group_ids = [
    aws_security_group.interface_endpoints.id,
  ]

  tags = {
    Name = "as-bank-${var.environment}-${replace(each.value, ".", "-")}"
  }
}
