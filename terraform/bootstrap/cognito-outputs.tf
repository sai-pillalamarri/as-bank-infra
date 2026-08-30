output "cognito_user_pool_id" {
  description = "Persistent Cognito user pool used by AS Bank."
  value       = aws_cognito_user_pool.as_bank.id
}

output "cognito_issuer" {
  description = "JWT issuer used by AS Bank resource servers."
  value       = "https://${aws_cognito_user_pool.as_bank.endpoint}"
}

output "cognito_login_base_url" {
  description = "Managed Cognito login endpoint used by the frontend."
  value       = "https://${aws_cognito_user_pool_domain.as_bank.domain}.auth.${var.aws_region}.amazoncognito.com"
}

output "cognito_resource_server_identifier" {
  description = "OAuth resource server identifier used for AS Bank API scopes."
  value       = aws_cognito_resource_server.api.identifier
}

output "cognito_frontend_clients" {
  description = "Environment-specific public Cognito clients."
  value = {
    for environment, client in aws_cognito_user_pool_client.frontend :
    environment => {
      client_id     = client.id
      callback_urls = client.callback_urls
      logout_urls   = client.logout_urls
    }
  }
}

output "cognito_demo_users" {
  description = "Synthetic Cognito identities used by the Stage 7 seed data."
  value = {
    for username, user in aws_cognito_user.demo :
    username => {
      username = user.username
      sub      = user.sub
      name     = local.cognito_demo_users[username].name
      email    = local.cognito_demo_users[username].email
      group    = local.cognito_demo_users[username].group
    }
  }
}
