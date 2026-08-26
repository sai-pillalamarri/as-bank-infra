terraform {
  required_version = "= 1.15.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.60.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "= 3.2.0"
    }
  }
}
