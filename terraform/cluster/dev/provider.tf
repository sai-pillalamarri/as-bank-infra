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

provider "helm" {
  kubernetes = {
    host                   = module.cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.cluster.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"

      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.cluster.cluster_name,
        "--region",
        var.aws_region,
      ]
    }
  }
}
