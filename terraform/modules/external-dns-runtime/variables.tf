variable "environment" {
  description = "Environment owning the ExternalDNS TXT records."
  type        = string
}

variable "domain_name" {
  description = "DNS suffix ExternalDNS is allowed to manage."
  type        = string
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ExternalDNS is allowed to manage."
  type        = string
}
