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

  # The pool is shared so Cognito sub values remain stable across environments.
  # Environment isolation comes from separate app client IDs validated by the APIs.
  cognito_frontend_clients = {
    dev = {
      callback_urls = [
        "https://dev.aslearnings.online/auth/callback",
      ]
      logout_urls = [
        "https://dev.aslearnings.online/",
      ]
    }

    qa = {
      callback_urls = [
        "https://qa.aslearnings.online/auth/callback",
      ]
      logout_urls = [
        "https://qa.aslearnings.online/",
      ]
    }

    prod = {
      callback_urls = [
        "https://aslearnings.online/auth/callback",
        "https://www.aslearnings.online/auth/callback",
      ]
      logout_urls = [
        "https://aslearnings.online/",
        "https://www.aslearnings.online/",
      ]
    }
  }

  cognito_roles = {
    CUSTOMER = {
      description = "AS Bank customer"
      precedence  = 30
    }

    OPERATIONS = {
      description = "AS Bank operations user"
      precedence  = 20
    }

    ADMIN = {
      description = "AS Bank administrator"
      precedence  = 10
    }
  }

  cognito_demo_users = {
    customer01 = {
      name  = "Avery Stone"
      email = "customer01@as-bank.example"
      group = "CUSTOMER"
    }

    customer02 = {
      name  = "Jordan Lee"
      email = "customer02@as-bank.example"
      group = "CUSTOMER"
    }

    customer03 = {
      name  = "Morgan Reed"
      email = "customer03@as-bank.example"
      group = "CUSTOMER"
    }

    customer04 = {
      name  = "Casey Brooks"
      email = "customer04@as-bank.example"
      group = "CUSTOMER"
    }

    operations01 = {
      name  = "Taylor Quinn"
      email = "operations01@as-bank.example"
      group = "OPERATIONS"
    }

    admin01 = {
      name  = "Riley Chen"
      email = "admin01@as-bank.example"
      group = "ADMIN"
    }
  }
}
