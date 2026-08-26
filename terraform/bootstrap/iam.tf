resource "aws_iam_role" "application_release" {
  name                 = "as-bank-application-release"
  max_session_duration = 3600

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.github_oidc_host}:aud" = "sts.amazonaws.com"
            "${local.github_oidc_host}:sub" = local.github_app_release_subject
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "application_release_ecr" {
  name = "as-bank-ecr-release"
  role = aws_iam_role.application_release.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GetRegistryToken"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
        ]
        Resource = "*"
      },
      {
        Sid    = "PublishApplicationImages"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:ListImages",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
        ]
        Resource = [
          for repository in aws_ecr_repository.application :
          repository.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role" "infrastructure_plan" {
  name                 = "as-bank-infrastructure-plan"
  max_session_duration = 3600

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.github_oidc_host}:aud" = "sts.amazonaws.com"
            "${local.github_oidc_host}:sub" = local.github_infra_plan_subject
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "infrastructure_plan_read_only" {
  role       = aws_iam_role.infrastructure_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy" "infrastructure_plan_state" {
  name = "as-bank-terraform-state-plan"
  role = aws_iam_role.infrastructure_plan.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListStateBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.terraform_state.arn
      },
      {
        Sid      = "ReadState"
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
      },
      {
        Sid    = "ManageStateLocks"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = "${aws_s3_bucket.terraform_state.arn}/*.tflock"
      }
    ]
  })
}

resource "aws_iam_role" "infrastructure_apply" {
  name                 = "as-bank-infrastructure-apply"
  max_session_duration = 3600

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.github_oidc_host}:aud" = "sts.amazonaws.com"
            "${local.github_oidc_host}:sub" = local.github_infra_apply_subject
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "infrastructure_apply_state" {
  name = "as-bank-terraform-state-apply"
  role = aws_iam_role.infrastructure_apply.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListStateBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.terraform_state.arn
      },
      {
        Sid    = "ReadWriteState"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
        ]
        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
      },
      {
        Sid    = "ManageStateLocks"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = "${aws_s3_bucket.terraform_state.arn}/*.tflock"
      }
    ]
  })
}

resource "aws_iam_role" "operator" {
  name                 = "as-bank-operator-role"
  max_session_duration = 3600

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.operator_user_name}"
        }
        Action = "sts:AssumeRole"
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "operator_admin" {

  #checkov:skip=CKV_AWS_274:AdministratorAccess is intentionally behind the MFA-protected operator STS role; the login user has no direct admin policy.

  role = aws_iam_role.operator.name

  # Administrative access moves behind MFA role assumption instead of staying on the login user.
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_user_policy" "operator_assume_role" {
  #checkov:skip=CKV_AWS_40:The single login user can only assume the MFA-protected operator role; adding an IAM group would not create another security boundary.

  name = "as-bank-assume-operator-role"
  user = var.operator_user_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = aws_iam_role.operator.arn
      }
    ]
  })
}
