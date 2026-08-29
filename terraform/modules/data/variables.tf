variable "environment" {
  description = "Environment that owns the database resources."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "vpc_id" {
  description = "VPC containing the RDS instances."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs used by the RDS subnet group."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "RDS requires private subnets in at least two availability zones."
  }
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs allowed to reach PostgreSQL."
  type        = set(string)

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "At least two private subnet CIDRs are required."
  }
}

variable "instance_class" {
  description = "RDS instance class used by each service database."
  type        = string
}

variable "multi_az" {
  description = "Whether the RDS instances use Multi-AZ."
  type        = bool
}

variable "backup_retention_period" {
  description = "Days that automated backups are retained while RDS is running."
  type        = number

  validation {
    condition = (
      var.backup_retention_period >= 1 &&
      var.backup_retention_period <= 35
    )
    error_message = "backup_retention_period must be between 1 and 35 days."
  }
}

variable "apply_immediately" {
  description = "Whether RDS changes bypass the maintenance window."
  type        = bool
}

variable "databases_enabled" {
  description = "Whether the billable RDS resources are present."
  type        = bool
  default     = true
}

variable "snapshot_identifiers" {
  description = "Final snapshots used to restore service databases."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for service in keys(var.snapshot_identifiers) :
      contains(["customer", "account", "transaction"], service)
    ])
    error_message = "Snapshot keys must be customer, account, or transaction."
  }
}

variable "database_password_version" {
  description = "Credential generation version. Increment deliberately when rotating database passwords."
  type        = number
  default     = 1

  validation {
    condition = (
      var.database_password_version >= 1 &&
      floor(var.database_password_version) == var.database_password_version
    )
    error_message = "database_password_version must be a positive integer."
  }
}

variable "final_snapshot_suffix" {
  description = "Unique suffix used for final snapshots during database teardown."
  type        = string
  default     = "manual"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.final_snapshot_suffix))
    error_message = "final_snapshot_suffix may contain only lowercase letters, numbers, and hyphens."
  }
}
