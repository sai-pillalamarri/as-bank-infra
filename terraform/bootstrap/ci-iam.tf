resource "aws_iam_role" "infrastructure_environment_plan" {
  for_each = local.infrastructure_environments

  name                 = "as-bank-infrastructure-${each.key}-plan"
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

resource "aws_iam_role_policy_attachment" "infrastructure_environment_plan_read_only" {
  for_each = local.infrastructure_environments

  role       = aws_iam_role.infrastructure_environment_plan[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy" "infrastructure_environment_plan_state" {
  for_each = local.infrastructure_environments

  name = "as-bank-${each.key}-terraform-state-plan"
  role = aws_iam_role.infrastructure_environment_plan[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadStateBucket"
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
        ]
        Resource = aws_s3_bucket.terraform_state.arn
      },
      {
        Sid    = "ReadEnvironmentState"
        Effect = "Allow"
        Action = "s3:GetObject"
        Resource = [
          "${aws_s3_bucket.terraform_state.arn}/bootstrap/terraform.tfstate",
          "${aws_s3_bucket.terraform_state.arn}/network/${each.key}/terraform.tfstate",
          "${aws_s3_bucket.terraform_state.arn}/cluster/${each.key}/terraform.tfstate",
          "${aws_s3_bucket.terraform_state.arn}/data/${each.key}/terraform.tfstate",
        ]
      },
      {
        Sid    = "ManagePlanLocks"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = [
          "${aws_s3_bucket.terraform_state.arn}/network/${each.key}/terraform.tfstate.tflock",
          "${aws_s3_bucket.terraform_state.arn}/cluster/${each.key}/terraform.tfstate.tflock",
          "${aws_s3_bucket.terraform_state.arn}/data/${each.key}/terraform.tfstate.tflock",
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy" "infrastructure_environment_data_plan" {
  #checkov:skip=CKV_AWS_355:GetRandomPassword does not support resource-level permissions; database secret reads are scoped to this environment.

  for_each = local.infrastructure_environments

  name = "as-bank-${each.key}-data-plan"
  role = aws_iam_role.infrastructure_environment_plan[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "GenerateDatabasePasswords"
        Effect   = "Allow"
        Action   = "secretsmanager:GetRandomPassword"
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
      },
      {
        Sid      = "ReadDatabaseCredentials"
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:as-bank/${each.key}/database/*"
      },
    ]
  })
}

resource "aws_iam_role" "infrastructure_environment_apply" {
  for_each = local.infrastructure_environments

  name                 = "as-bank-infrastructure-${each.key}-apply"
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

resource "aws_iam_role_policy_attachment" "infrastructure_environment_apply_read_only" {
  for_each = local.infrastructure_environments

  role       = aws_iam_role.infrastructure_environment_apply[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy" "infrastructure_environment_apply_state" {
  for_each = local.infrastructure_environments

  name = "as-bank-${each.key}-terraform-state-apply"
  role = aws_iam_role.infrastructure_environment_apply[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadStateBucket"
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
        ]
        Resource = aws_s3_bucket.terraform_state.arn
      },
      {
        Sid      = "ReadBootstrapState"
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.terraform_state.arn}/bootstrap/terraform.tfstate"
      },
      {
        Sid    = "ManageEnvironmentState"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
        ]
        Resource = [
          "${aws_s3_bucket.terraform_state.arn}/network/${each.key}/terraform.tfstate",
          "${aws_s3_bucket.terraform_state.arn}/cluster/${each.key}/terraform.tfstate",
          "${aws_s3_bucket.terraform_state.arn}/data/${each.key}/terraform.tfstate",
        ]
      },
      {
        Sid    = "ManageApplyLocks"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = [
          "${aws_s3_bucket.terraform_state.arn}/network/${each.key}/terraform.tfstate.tflock",
          "${aws_s3_bucket.terraform_state.arn}/cluster/${each.key}/terraform.tfstate.tflock",
          "${aws_s3_bucket.terraform_state.arn}/data/${each.key}/terraform.tfstate.tflock",
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy" "infrastructure_environment_network_write" {
  for_each = local.infrastructure_environments

  name = "as-bank-${each.key}-network-write"
  role = aws_iam_role.infrastructure_environment_apply[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:AllocateAddress",
          "ec2:AssociateRouteTable",
          "ec2:AttachInternetGateway",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:CreateInternetGateway",
          "ec2:CreateNatGateway",
          "ec2:CreateRoute",
          "ec2:CreateRouteTable",
          "ec2:CreateSecurityGroup",
          "ec2:CreateSubnet",
          "ec2:CreateTags",
          "ec2:CreateVpc",
          "ec2:CreateVpcEndpoint",
          "ec2:DeleteInternetGateway",
          "ec2:DeleteNatGateway",
          "ec2:DeleteRoute",
          "ec2:DeleteRouteTable",
          "ec2:DeleteSecurityGroup",
          "ec2:DeleteSubnet",
          "ec2:DeleteTags",
          "ec2:DeleteVpc",
          "ec2:DeleteVpcEndpoints",
          "ec2:DetachInternetGateway",
          "ec2:DisassociateAddress",
          "ec2:DisassociateRouteTable",
          "ec2:ModifySubnetAttribute",
          "ec2:ModifyVpcAttribute",
          "ec2:ModifyVpcEndpoint",
          "ec2:ReleaseAddress",
          "ec2:ReplaceRoute",
          "ec2:ReplaceRouteTableAssociation",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
        ]
        Resource = "*"

        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "infrastructure_environment_data_write" {
  #checkov:skip=CKV_AWS_355:RDS lifecycle calls and password generation need wildcard resources; the role is environment-specific and region-bounded.
  #checkov:skip=CKV_AWS_290:Resource scoping is used for Secrets Manager where AWS supports it; the remaining data actions are constrained by the environment role and region.

  for_each = local.infrastructure_environments

  name = "as-bank-${each.key}-data-write"
  role = aws_iam_role.infrastructure_environment_apply[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ManageRds"
        Effect = "Allow"
        Action = [
          "rds:AddTagsToResource",
          "rds:CreateDBInstance",
          "rds:CreateDBSnapshot",
          "rds:CreateDBSubnetGroup",
          "rds:DeleteDBInstance",
          "rds:DeleteDBSnapshot",
          "rds:DeleteDBSubnetGroup",
          "rds:ModifyDBInstance",
          "rds:ModifyDBSubnetGroup",
          "rds:RemoveTagsFromResource",
          "rds:RestoreDBInstanceFromDBSnapshot",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
      },
      {
        Sid      = "GenerateDatabasePasswords"
        Effect   = "Allow"
        Action   = "secretsmanager:GetRandomPassword"
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
      },
      {
        Sid    = "ManageDatabaseSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:CreateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:PutSecretValue",
          "secretsmanager:RestoreSecret",
          "secretsmanager:TagResource",
          "secretsmanager:UntagResource",
          "secretsmanager:UpdateSecret",
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:as-bank/${each.key}/database/*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "infrastructure_environment_cluster_write" {
  for_each = local.infrastructure_environments

  name = "as-bank-${each.key}-cluster-write"
  role = aws_iam_role.infrastructure_environment_apply[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ManageEKS"
        Effect = "Allow"
        Action = [
          "eks:AssociateAccessPolicy",
          "eks:CreateAccessEntry",
          "eks:CreateAddon",
          "eks:CreateCluster",
          "eks:CreateNodegroup",
          "eks:CreatePodIdentityAssociation",
          "eks:DeleteAccessEntry",
          "eks:DeleteAddon",
          "eks:DeleteCluster",
          "eks:DeleteNodegroup",
          "eks:DeletePodIdentityAssociation",
          "eks:DisassociateAccessPolicy",
          "eks:TagResource",
          "eks:UntagResource",
          "eks:UpdateAccessEntry",
          "eks:UpdateAddon",
          "eks:UpdateClusterConfig",
          "eks:UpdateClusterVersion",
          "eks:UpdateNodegroupConfig",
          "eks:UpdateNodegroupVersion",
          "eks:UpdatePodIdentityAssociation",
        ]
        Resource = "*"

        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
      },
      {
        Sid    = "ManageEKSLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:PutRetentionPolicy",
          "logs:TagResource",
          "logs:UntagResource",
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/eks/as-bank-${each.key}/cluster:*"
      },
      {
        Sid    = "ManageKarpenterQueue"
        Effect = "Allow"
        Action = [
          "sqs:CreateQueue",
          "sqs:DeleteQueue",
          "sqs:SetQueueAttributes",
          "sqs:TagQueue",
          "sqs:UntagQueue",
        ]
        Resource = "arn:aws:sqs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:as-bank-${each.key}-karpenter"
      },
      {
        Sid    = "ManageKarpenterEvents"
        Effect = "Allow"
        Action = [
          "events:DeleteRule",
          "events:PutRule",
          "events:PutTargets",
          "events:RemoveTargets",
          "events:TagResource",
          "events:UntagResource",
        ]
        Resource = "arn:aws:events:${var.aws_region}:${data.aws_caller_identity.current.account_id}:rule/as-bank-${each.key}-karpenter-*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "infrastructure_environment_iam_write" {
  for_each = local.infrastructure_environments

  name = "as-bank-${each.key}-iam-write"
  role = aws_iam_role.infrastructure_environment_apply[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ManageEnvironmentRoles"
        Effect = "Allow"
        Action = [
          "iam:AttachRolePolicy",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:DeleteRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:UpdateAssumeRolePolicy",
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/as-bank-${each.key}-*"
      },
      {
        Sid    = "ManageEnvironmentPolicies"
        Effect = "Allow"
        Action = [
          "iam:CreatePolicy",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicy",
          "iam:DeletePolicyVersion",
          "iam:SetDefaultPolicyVersion",
          "iam:TagPolicy",
          "iam:UntagPolicy",
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/as-bank-${each.key}-*"
      },
      {
        Sid      = "PassEnvironmentRoles"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/as-bank-${each.key}-*"

        Condition = {
          StringEquals = {
            "iam:PassedToService" = [
              "ec2.amazonaws.com",
              "eks.amazonaws.com",
              "pods.eks.amazonaws.com",
            ]
          }
        }
      },
      {
        Sid      = "CreateRequiredServiceLinkedRoles"
        Effect   = "Allow"
        Action   = "iam:CreateServiceLinkedRole"
        Resource = "*"

        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = [
              "autoscaling.amazonaws.com",
              "eks.amazonaws.com",
              "eks-nodegroup.amazonaws.com",
              "rds.amazonaws.com",
            ]
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "infrastructure_apply_read_only" {
  role       = aws_iam_role.infrastructure_apply.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy" "infrastructure_apply_bootstrap_write" {
  #checkov:skip=CKV_AWS_355:Wildcard statements are limited to account-level bootstrap actions; other mutable AS Bank resources are scoped.
  #checkov:skip=CKV_AWS_290:Some bootstrap APIs cannot all be expressed with resource ARNs; Spot service-linked-role creation is constrained by iam:AWSServiceName.

  name = "as-bank-bootstrap-write"
  role = aws_iam_role.infrastructure_apply.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ManageBudget"
        Effect = "Allow"
        Action = [
          "aws-portal:ModifyBilling",
          "budgets:ModifyBudget",
          "budgets:TagResource",
          "budgets:UntagResource",
        ]
        Resource = "*"
      },
      {
        Sid    = "ManageApplicationRepositories"
        Effect = "Allow"
        Action = [
          "ecr:CreateRepository",
          "ecr:PutImageScanningConfiguration",
          "ecr:PutImageTagMutability",
          "ecr:TagResource",
          "ecr:UntagResource",
        ]
        Resource = "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/as-bank/*"

        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
      },
      {
        Sid    = "ManageAsBankRoles"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:DeleteRolePolicy",
          "iam:PutRolePolicy",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:UpdateRole",
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/as-bank-*"
      },
      {
        Sid    = "ManageInfrastructureReadOnlyAttachments"
        Effect = "Allow"
        Action = [
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/as-bank-infrastructure-plan",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/as-bank-infrastructure-apply",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/as-bank-infrastructure-dev-plan",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/as-bank-infrastructure-dev-apply",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/as-bank-infrastructure-prod-plan",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/as-bank-infrastructure-prod-apply",
        ]

        Condition = {
          ArnEquals = {
            "iam:PolicyARN" = "arn:aws:iam::aws:policy/ReadOnlyAccess"
          }
        }
      },
      {
        Sid    = "ManageOperatorAdministratorAttachment"
        Effect = "Allow"
        Action = [
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/as-bank-operator-role"

        Condition = {
          ArnEquals = {
            "iam:PolicyARN" = "arn:aws:iam::aws:policy/AdministratorAccess"
          }
        }
      },
      {
        Sid    = "ManageOperatorAssumeRolePolicy"
        Effect = "Allow"
        Action = [
          "iam:DeleteUserPolicy",
          "iam:PutUserPolicy",
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.operator_user_name}"
      },
      {
        Sid    = "ManageGitHubOidcProvider"
        Effect = "Allow"
        Action = [
          "iam:AddClientIDToOpenIDConnectProvider",
          "iam:RemoveClientIDFromOpenIDConnectProvider",
          "iam:TagOpenIDConnectProvider",
          "iam:UntagOpenIDConnectProvider",
          "iam:UpdateOpenIDConnectProviderThumbprint",
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.github_oidc_host}"
      },
      {
        Sid    = "ManageHostedZoneTags"
        Effect = "Allow"
        Action = [
          "route53:ChangeTagsForResource",
        ]
        Resource = aws_route53_zone.primary.arn
      },
      {
        Sid    = "HardenTerraformStateBucket"
        Effect = "Allow"
        Action = [
          "s3:PutBucketPublicAccessBlock",
          "s3:PutBucketTagging",
          "s3:PutBucketVersioning",
          "s3:PutEncryptionConfiguration",
        ]
        Resource = aws_s3_bucket.terraform_state.arn
      },
      {
        Sid      = "CreateSpotServiceLinkedRole"
        Effect   = "Allow"
        Action   = "iam:CreateServiceLinkedRole"
        Resource = "*"

        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = "spot.amazonaws.com"
          }
        }
      },
    ]
  })
}
