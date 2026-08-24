output "terraform_state_bucket_name" {
  description = "S3 bucket used for Terraform remote state."
  value       = aws_s3_bucket.terraform_state.id
}

output "ecr_repository_urls" {
  description = "ECR repository URLs used by the application release pipeline."
  value = {
    for name, repository in aws_ecr_repository.application :
    name => repository.repository_url
  }
}

output "route53_zone_id" {
  description = "Route 53 hosted zone ID for aslearnings.online."
  value       = aws_route53_zone.primary.zone_id
}

output "route53_name_servers" {
  description = "Route 53 nameservers that must be configured at Hostinger."
  value       = aws_route53_zone.primary.name_servers
}

output "github_oidc_provider_arn" {
  description = "IAM OIDC provider trusted by GitHub Actions."
  value       = aws_iam_openid_connect_provider.github.arn
}

output "application_release_role_arn" {
  description = "Role assumed by the application release workflow."
  value       = aws_iam_role.application_release.arn
}

output "infrastructure_plan_role_arn" {
  description = "Role assumed by Terraform pull-request plans."
  value       = aws_iam_role.infrastructure_plan.arn
}

output "infrastructure_apply_role_arn" {
  description = "Role assumed by Terraform apply workflows."
  value       = aws_iam_role.infrastructure_apply.arn
}

output "operator_role_arn" {
  description = "MFA-protected role used for human AWS access."
  value       = aws_iam_role.operator.arn
}
