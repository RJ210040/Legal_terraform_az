variable "org_short" {
  description = "Short organization identifier (2-4 chars)"
  type        = string

  validation {
    condition     = length(var.org_short) >= 2 && length(var.org_short) <= 4
    error_message = "org_short must be between 2 and 4 characters."
  }
}

variable "project" {
  description = "Project name"
  type        = string

  validation {
    condition     = length(var.project) >= 2 && length(var.project) <= 12
    error_message = "project must be between 2 and 12 characters."
  }
}

variable "environment" {
  description = "Environment name (dev, mvp, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "mvp", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, mvp, staging, prod."
  }
}

variable "region" {
  description = "Azure region"
  type        = string
}

variable "sequence" {
  description = "Sequence number for resource uniqueness"
  type        = number
  default     = 1
}

variable "extra_tags" {
  description = "Additional tags to merge with common tags"
  type        = map(string)
  default     = {}
}
