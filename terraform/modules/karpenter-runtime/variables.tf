variable "cluster_name" {
  description = "EKS cluster managed by Karpenter."
  type        = string
}

variable "interruption_queue_name" {
  description = "SQS queue used for Karpenter interruption handling."
  type        = string
}

variable "node_role_name" {
  description = "IAM role used by EC2 nodes launched by Karpenter."
  type        = string
}

variable "cluster_security_group_id" {
  description = "EKS cluster security group attached to Karpenter nodes."
  type        = string
}

variable "capacity_type" {
  description = "Capacity type used by the application NodePool."
  type        = string

  validation {
    condition     = contains(["spot", "on-demand"], var.capacity_type)
    error_message = "Capacity type must be spot or on-demand."
  }
}

variable "controller_replicas" {
  description = "Number of Karpenter controller replicas."
  type        = number
}

variable "environment" {
  description = "Environment whose nodes Karpenter provisions."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be dev or prod."
  }
}
