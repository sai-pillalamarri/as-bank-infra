variable "aws_region" {
  description = "Primary AWS region for AS Bank."
  type        = string
  default     = "us-east-1"
}

variable "install_karpenter" {
  description = "Install the Karpenter controller and node provisioning configuration."
  type        = bool
  default     = true
}

variable "install_argocd" {
  description = "Install Argo CD and the root GitOps application."
  type        = bool
  default     = true
}

variable "install_external_secrets" {
  description = "Install External Secrets Operator."
  type        = bool
  default     = true
}

variable "install_kyverno" {
  description = "Install Kyverno admission controllers and policy CRDs."
  type        = bool
  default     = true
}
