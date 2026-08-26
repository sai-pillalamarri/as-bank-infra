resource "aws_eip" "nat" {
  for_each = local.nat_availability_zones

  domain = "vpc"

  tags = {
    Name = "as-bank-${var.environment}-nat-${each.key}"
  }
}

resource "aws_nat_gateway" "this" {
  for_each = local.nat_availability_zones

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = var.public_subnet_ids_by_az[each.key]

  tags = {
    Name = "as-bank-${var.environment}-${each.key}"
  }
}

resource "aws_route" "private_internet" {
  for_each = var.private_route_table_ids_by_az

  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = aws_nat_gateway.this[
    var.environment == "prod" ? each.key : local.primary_az
  ].id
}
