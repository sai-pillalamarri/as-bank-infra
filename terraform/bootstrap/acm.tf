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
}

resource "aws_route53_record" "alb_certificate_validation" {
  for_each = {
    for option in aws_acm_certificate.alb.domain_validation_options :
    option.domain_name => {
      name   = option.resource_record_name
      record = option.resource_record_value
      type   = option.resource_record_type
    }
  }

  zone_id = aws_route53_zone.primary.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60

  records = [
    each.value.record,
  ]
}

resource "aws_acm_certificate_validation" "alb" {
  certificate_arn = aws_acm_certificate.alb.arn

  validation_record_fqdns = [
    for record in aws_route53_record.alb_certificate_validation :
    record.fqdn
  ]

  depends_on = [
    aws_iam_role_policy.infrastructure_apply_bootstrap_write,
  ]
}
