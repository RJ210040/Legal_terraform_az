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

variable "retention_in_days" {
  description = "Data retention in days"
  type        = number
  default     = 30
}

variable "daily_quota_gb" {
  description = "Daily data cap in GB (-1 for unlimited)"
  type        = number
  default     = -1
}

variable "enable_container_insights" {
  description = "Enable Container Insights"
  type        = bool
  default     = true
}
