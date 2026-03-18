variable "name" {
  description = "Storage account name"
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

variable "account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "Replication type (LRS, ZRS, GRS)"
  type        = string
  default     = "LRS"
}

variable "access_tier" {
  description = "Access tier (Hot, Cool)"
  type        = string
  default     = "Hot"
}

variable "containers" {
  description = "List of blob containers to create"
  type        = list(string)
  default     = ["raw", "processed", "logs"]
}

variable "file_shares" {
  description = "List of file shares to create"
  type        = list(string)
  default     = []
}

variable "file_share_quota_gb" {
  description = "File share quota in GB"
  type        = number
  default     = 50
}

variable "enable_versioning" {
  description = "Enable blob versioning"
  type        = bool
  default     = false
}

variable "blob_soft_delete_days" {
  description = "Blob soft delete retention days"
  type        = number
  default     = 7
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "allowed_subnet_ids" {
  description = "List of subnet IDs to allow access"
  type        = list(string)
  default     = []
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID"
  type        = string
  default     = null
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
