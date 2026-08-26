resource "aws_security_group" "interface_endpoints" {
  name_prefix = "as-bank-${var.environment}-endpoints-"
  description = "HTTPS access to private AWS service endpoints."
  vpc_id      = var.vpc_id

  tags = {
    Name = "as-bank-${var.environment}-endpoints"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "interface_endpoints_https" {
  security_group_id = aws_security_group.interface_endpoints.id
  description       = "HTTPS from the VPC to AWS interface endpoints."

  cidr_ipv4   = data.aws_vpc.this.cidr_block
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}
