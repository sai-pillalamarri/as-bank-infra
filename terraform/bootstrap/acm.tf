resource "aws_acm_certificate" "alb" {
  # checkov:skip=CKV2_AWS_71:The wildcard is intentional so one certificate covers the project's single-label subdomains.

  domain_name = "aslearnings.online"

  subject_alternative_names = [
    "*.aslearnings.online",
  ]

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_iam_role_policy.infrastructure_apply_bootstrap_write,
  ]
}

# ACM uses the same DNS validation record for the apex and its wildcard.
moved {
  from = aws_route53_record.alb_certificate_validation["*.aslearnings.online"]
  to   = aws_route53_record.alb_certificate_validation
}

resource "aws_route53_record" "alb_certificate_validation" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = local.alb_certificate_validation_option.resource_record_name
  type    = local.alb_certificate_validation_option.resource_record_type
  ttl     = 60

  records = [
    local.alb_certificate_validation_option.resource_record_value,
  ]
}

resource "aws_acm_certificate_validation" "alb" {
  certificate_arn = aws_acm_certificate.alb.arn

  validation_record_fqdns = [
    aws_route53_record.alb_certificate_validation.fqdn,
  ]
}

resource "aws_acm_certificate" "cloudfront" {
  # checkov:skip=CKV2_AWS_71:The wildcard is intentional so CloudFront can serve every single-label AS Bank hostname.

  domain_name = "aslearnings.online"

  subject_alternative_names = [
    "*.aslearnings.online",
  ]

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_iam_role_policy.infrastructure_apply_bootstrap_write,
  ]
}

resource "aws_acm_certificate_validation" "cloudfront" {
  certificate_arn = aws_acm_certificate.cloudfront.arn

  # ACM reuses the existing domain-validation CNAME for certificates
  # covering the same names in this account.
  validation_record_fqdns = [
    aws_route53_record.alb_certificate_validation.fqdn,
  ]
}
