locals {
  ecr_repositories = toset([
    "customer-service",
    "account-service",
    "transaction-service",
    "frontend",
  ])

  github_oidc_host = "token.actions.githubusercontent.com"

  # Release credentials are only issued to the application repository on main.
  github_app_release_subject = "repo:${var.github_owner}@${var.github_owner_id}/as-bank-app@${var.as_bank_app_repository_id}:ref:refs/heads/main"

  # Terraform plans run from pull requests; apply credentials remain limited to main.
  github_infra_plan_subject  = "repo:${var.github_owner}@${var.github_owner_id}/as-bank-infra@${var.as_bank_infra_repository_id}:pull_request"
  github_infra_apply_subject = "repo:${var.github_owner}@${var.github_owner_id}/as-bank-infra@${var.as_bank_infra_repository_id}:ref:refs/heads/main"

  infrastructure_environments = toset([
    "dev",
    "prod",
  ])
}
