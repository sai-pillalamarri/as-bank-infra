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

data "aws_ec2_managed_prefix_list" "cloudfront_origin" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group" "alb_frontend" {
  #checkov:skip=CKV2_AWS_5:The AWS Load Balancer Controller attaches this group to the ALB from the GitOps Ingress.
  name        = "as-bank-${var.environment}-alb-frontend"
  description = "CloudFront-only HTTPS access to the shared application ALB."
  vpc_id      = var.vpc_id

  tags = {
    Name = "as-bank-${var.environment}-alb-frontend"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_frontend_https_cloudfront" {
  security_group_id = aws_security_group.alb_frontend.id
  description       = "HTTPS from the AWS CloudFront origin-facing network."

  prefix_list_id = data.aws_ec2_managed_prefix_list.cloudfront_origin.id
  from_port      = 443
  to_port        = 443
  ip_protocol    = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_frontend_to_targets" {
  security_group_id = aws_security_group.alb_frontend.id
  description       = "Application traffic from the ALB to targets in the VPC."

  cidr_ipv4   = data.aws_vpc.this.cidr_block
  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"
}
