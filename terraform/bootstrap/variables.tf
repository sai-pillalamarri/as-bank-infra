variable "aws_region" {
  description = "Primary AWS region for AS Bank."
  type        = string
  default     = "us-east-1"
}

variable "budget_alert_email" {
  description = "Email address that receives AWS Budget alerts."
  type        = string
  sensitive   = true

}

variable "github_owner" {
  description = "GitHub owner of the AS Bank repositories."
  type        = string
}

variable "github_owner_id" {
  description = "Immutable numeric GitHub owner ID used in OIDC subject claims."
  type        = string
}

variable "as_bank_app_repository_id" {
  description = "Immutable numeric GitHub repository ID for as-bank-app."
  type        = string
}

variable "as_bank_infra_repository_id" {
  description = "Immutable numeric GitHub repository ID for as-bank-infra."
  type        = string
}

variable "operator_user_name" {
  description = "IAM user that assumes the human operator role."
  type        = string
  default     = "as-bank-operator"
}
