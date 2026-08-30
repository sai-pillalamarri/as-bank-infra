resource "aws_cognito_user_pool" "as_bank" {
  name                = "as-bank"
  deletion_protection = "ACTIVE"
  user_pool_tier      = "LITE"

  alias_attributes  = ["email"]
  mfa_configuration = "OPTIONAL"

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "admin_only"
      priority = 1
    }
  }

  password_policy {
    minimum_length                   = 14
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 1
  }

  software_token_mfa_configuration {
    enabled = true
  }

  username_configuration {
    case_sensitive = false
  }
}

resource "aws_cognito_resource_server" "api" {
  identifier = "https://api.aslearnings.online"
  name       = "as-bank-api"

  user_pool_id = aws_cognito_user_pool.as_bank.id

  scope {
    scope_name        = "read"
    scope_description = "Read AS Bank resources"
  }

  scope {
    scope_name        = "write"
    scope_description = "Change AS Bank resources"
  }
}

resource "aws_cognito_user_pool_client" "frontend" {
  for_each = local.cognito_frontend_clients

  name         = "as-bank-${each.key}-frontend"
  user_pool_id = aws_cognito_user_pool.as_bank.id

  generate_secret = false

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes = [
    "openid",
    "email",
    "profile",
    "${aws_cognito_resource_server.api.identifier}/read",
    "${aws_cognito_resource_server.api.identifier}/write",
  ]

  callback_urls        = each.value.callback_urls
  logout_urls          = each.value.logout_urls
  default_redirect_uri = each.value.callback_urls[0]

  supported_identity_providers = ["COGNITO"]

  access_token_validity  = 15
  id_token_validity      = 15
  refresh_token_validity = 1

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  enable_token_revocation       = true
  prevent_user_existence_errors = "ENABLED"
}

resource "aws_cognito_user_pool_domain" "as_bank" {
  domain       = "as-bank-aslearnings-online"
  user_pool_id = aws_cognito_user_pool.as_bank.id
}

resource "aws_cognito_user_group" "role" {
  for_each = local.cognito_roles

  name         = each.key
  user_pool_id = aws_cognito_user_pool.as_bank.id

  description = each.value.description
  precedence  = each.value.precedence
}

resource "aws_cognito_user" "demo" {
  for_each = local.cognito_demo_users

  user_pool_id = aws_cognito_user_pool.as_bank.id
  username     = each.key

  # Demo identities do not own real mailboxes, so Cognito must not send invitations.
  message_action = "SUPPRESS"

  attributes = {
    name           = each.value.name
    email          = each.value.email
    email_verified = true
  }
}

resource "aws_cognito_user_in_group" "demo" {
  for_each = local.cognito_demo_users

  user_pool_id = aws_cognito_user_pool.as_bank.id
  username     = aws_cognito_user.demo[each.key].username
  group_name   = aws_cognito_user_group.role[each.value.group].name
}
