provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "as-bank"
      ManagedBy   = "terraform"
      Environment = local.environment
      CostCenter  = "learning"
      Repository  = "as-bank-infra"
    }
  }
}
