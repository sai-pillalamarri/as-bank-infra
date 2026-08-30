resource "aws_iam_role_policy" "infrastructure_apply_cognito_write" {
  #checkov:skip=CKV_AWS_355:Cognito create operations do not support resource-level permissions; the action list is limited and region-bounded.
  #checkov:skip=CKV_AWS_290:The bootstrap role needs Cognito write calls to provision persistent authentication resources through CI.

  name = "as-bank-cognito-write"
  role = aws_iam_role.infrastructure_apply.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ManageCognito"
        Effect = "Allow"
        Action = [
          "cognito-idp:AdminAddUserToGroup",
          "cognito-idp:AdminCreateUser",
          "cognito-idp:AdminDeleteUser",
          "cognito-idp:AdminDeleteUserAttributes",
          "cognito-idp:AdminDisableUser",
          "cognito-idp:AdminEnableUser",
          "cognito-idp:AdminRemoveUserFromGroup",
          "cognito-idp:AdminSetUserPassword",
          "cognito-idp:AdminUpdateUserAttributes",
          "cognito-idp:CreateGroup",
          "cognito-idp:CreateResourceServer",
          "cognito-idp:CreateUserPool",
          "cognito-idp:CreateUserPoolClient",
          "cognito-idp:CreateUserPoolDomain",
          "cognito-idp:DeleteGroup",
          "cognito-idp:DeleteResourceServer",
          "cognito-idp:DeleteUserPool",
          "cognito-idp:DeleteUserPoolClient",
          "cognito-idp:DeleteUserPoolDomain",
          "cognito-idp:SetUserPoolMfaConfig",
          "cognito-idp:TagResource",
          "cognito-idp:UntagResource",
          "cognito-idp:UpdateGroup",
          "cognito-idp:UpdateResourceServer",
          "cognito-idp:UpdateUserPool",
          "cognito-idp:UpdateUserPoolClient"
        ]
        Resource = "*"

        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
      }
    ]
  })
}
