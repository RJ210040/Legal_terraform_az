variable "workspace_name" {
  description = "Log Analytics workspace name"
  type        = string
}

variable "app_insights_name" {
  description = "Application Insights name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "sku" {
  description = "Log Analytics SKU"
  type        = string
  default     = "PerGB2018"
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

variable "application_type" {
  description = "Application Insights type"
  type        = string
  default     = "web"
}

variable "sampling_percentage" {
  description = "Sampling percentage"
  type        = number
  default     = 100
}

variable "disable_ip_masking" {
  description = "Disable IP masking"
  type        = bool
  default     = false
}

variable "enable_container_insights" {
  description = "Enable Container Insights solution"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
