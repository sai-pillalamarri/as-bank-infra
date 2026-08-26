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
