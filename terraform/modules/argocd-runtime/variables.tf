variable "environment" {
  description = "Environment managed by this Argo CD instance."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be dev or prod."
  }
}

variable "gitops_repository_url" {
  description = "Git repository containing the desired Kubernetes state."
  type        = string
}

variable "gitops_revision" {
  description = "Git revision Argo CD follows."
  type        = string
  default     = "main"
}

variable "ecr_registry" {
  description = "Private ECR registry injected into Argo CD manifest generation."
  type        = string

  validation {
    condition = can(regex(
      "^[0-9]{12}\\.dkr\\.ecr\\.[a-z0-9-]+\\.amazonaws\\.com$",
      var.ecr_registry
    ))
    error_message = "ecr_registry must be an AWS private ECR registry hostname."
  }
}
