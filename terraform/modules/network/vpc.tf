resource "aws_vpc" "this" {
  #checkov:skip=CKV2_AWS_11:Flow logs are not required for Stage 4 and would add paid logging to persistent VPCs.

  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "as-bank-${var.environment}"
  }
}

resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "as-bank-${var.environment}-default"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "as-bank-${var.environment}"
  }
}
