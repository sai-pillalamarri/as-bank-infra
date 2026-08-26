variable "environment" {
  description = "Environment that owns the cluster resources."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be dev or prod."
  }
}

variable "vpc_id" {
  description = "VPC created by the persistent network layer."
  type        = string
}

variable "public_subnet_ids_by_az" {
  description = "Public subnet IDs keyed by availability zone."
  type        = map(string)
}

variable "private_subnet_ids_by_az" {
  description = "Private subnet IDs keyed by availability zone."
  type        = map(string)
}

variable "private_route_table_ids_by_az" {
  description = "Private route table IDs keyed by availability zone."
  type        = map(string)
}

variable "operator_role_arn" {
  description = "MFA-protected human operator role granted administrative Kubernetes access."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version used by the EKS control plane and bootstrap node group."
  type        = string
}

variable "bootstrap_instance_types" {
  description = "EC2 instance types used by the managed bootstrap node group."
  type        = list(string)
}

variable "bootstrap_min_size" {
  description = "Minimum number of bootstrap nodes."
  type        = number
}

variable "bootstrap_desired_size" {
  description = "Initial number of bootstrap nodes."
  type        = number
}

variable "bootstrap_max_size" {
  description = "Maximum number of bootstrap nodes."
  type        = number
}

variable "automation_role_arn" {
  description = "Environment apply role used by Terraform automation."
  type        = string
}

variable "plan_role_arn" {
  description = "Environment plan role that reads Kubernetes state during Terraform plans."
  type        = string
}
