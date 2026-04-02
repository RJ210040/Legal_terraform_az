variable "state_resource_group_name" {
  description = "Resource group for Terraform state"
  type        = string
}

variable "state_storage_account_name" {
  description = "Storage account for Terraform state"
  type        = string
}

variable "state_container_name" {
  description = "Container for Terraform state"
  type        = string
  default     = "tfstate"
}

variable "org_short" {
  description = "Short organization identifier (2-4 chars)"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "legal"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "sequence" {
  description = "Sequence number for resource uniqueness"
  type        = number
  default     = 1
}

variable "extra_tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
