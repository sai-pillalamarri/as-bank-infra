variable "aws_region" {
  description = "Primary AWS region for AS Bank."
  type        = string
  default     = "us-east-1"
}

variable "databases_enabled" {
  description = "Whether the billable RDS instances are running."
  type        = bool
  default     = true
}

variable "snapshot_identifiers" {
  description = "Final snapshots used to restore service databases."
  type        = map(string)
  default     = {}
}

variable "database_password_version" {
  description = "Database credential version used for deliberate password rotation."
  type        = number
  default     = 1
}

variable "final_snapshot_suffix" {
  description = "Unique suffix used for final snapshots during database teardown."
  type        = string
  default     = "manual"
}
