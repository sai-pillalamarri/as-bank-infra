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
