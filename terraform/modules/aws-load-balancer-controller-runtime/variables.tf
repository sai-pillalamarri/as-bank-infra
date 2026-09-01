variable "cluster_name" {
  description = "EKS cluster managed by the AWS Load Balancer Controller."
  type        = string
}

variable "aws_region" {
  description = "AWS region containing the EKS cluster."
  type        = string
}

variable "vpc_id" {
  description = "VPC where the controller creates load balancers."
  type        = string
}
