resource "random_password" "cloudfront_origin_header_name" {
  length  = 20
  special = false
}

resource "random_password" "cloudfront_origin_header_value" {
  length  = 48
  special = false
}

resource "aws_secretsmanager_secret" "cloudfront_origin_header" {
  # checkov:skip=CKV_AWS_149:The AWS-managed Secrets Manager key is sufficient for this single-account origin credential.
  # checkov:skip=CKV2_AWS_57:Rotation requires CloudFront and the ALB listener rule to change together.
  name        = "as-bank/dev/edge/cloudfront-origin-header"
  description = "Credential used to identify CloudFront requests at the dev ALB."

  recovery_window_in_days = 7

  lifecycle {
    # The credential must survive the normal cluster teardown cycle.
    prevent_destroy = true
  }

  depends_on = [
    aws_iam_role_policy.infrastructure_apply_bootstrap_write,
  ]
}

resource "aws_secretsmanager_secret_version" "cloudfront_origin_header" {
  secret_id = aws_secretsmanager_secret.cloudfront_origin_header.id

  secret_string = jsonencode({
    name  = "X-ASB-${random_password.cloudfront_origin_header_name.result}"
    value = random_password.cloudfront_origin_header_value.result
  })
}
