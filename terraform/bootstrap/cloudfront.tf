data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewer"
}

data "aws_cloudfront_response_headers_policy" "security_headers" {
  name = "Managed-SecurityHeadersPolicy"
}

resource "aws_cloudfront_distribution" "dev" {
  # checkov:skip=CKV_AWS_374:No geographic restriction is required for the dev edge.
  # checkov:skip=CKV_AWS_310:Multi-region origin failover is explicitly outside this project's scope.
  # checkov:skip=CKV_AWS_86:CloudFront access-log storage is outside the Stage 7 edge scope.
  # checkov:skip=CKV_AWS_68:Stage 7 does not add a WAF WebACL; origin access is protected at the ALB.
  # checkov:skip=CKV2_AWS_47:This policy depends on a WAF WebACL, which is not part of the Stage 7 design.

  origin {
    domain_name = "origin-dev.aslearnings.online"
    origin_id   = "as-bank-dev-alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"

      origin_ssl_protocols = [
        "TLSv1.2",
      ]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "AS Bank dev edge"

  aliases = [
    "dev.aslearnings.online",
    "api-dev.aslearnings.online",
  ]

  default_cache_behavior {
    target_origin_id = "as-bank-dev-alb"

    allowed_methods = [
      "DELETE",
      "GET",
      "HEAD",
      "OPTIONS",
      "PATCH",
      "POST",
      "PUT",
    ]

    cached_methods = [
      "GET",
      "HEAD",
    ]

    cache_policy_id = data.aws_cloudfront_cache_policy.caching_disabled.id

    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id

    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.security_headers.id

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cloudfront.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # The apply role gains CloudFront write access in the same Terraform run.
  depends_on = [
    aws_iam_role_policy.infrastructure_apply_bootstrap_write,
  ]
}
