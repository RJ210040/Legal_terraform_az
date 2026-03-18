variable "name" {
  description = "Service Bus namespace name"
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
  description = "SKU (Basic, Standard, or Premium)"
  type        = string
  default     = "Standard"
}

variable "local_auth_enabled" {
  description = "Enable SAS-based authentication"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "queues" {
  description = "List of queues to create"
  type        = list(string)
  default     = []
}

variable "max_delivery_count" {
  description = "Max delivery attempts before dead-lettering"
  type        = number
  default     = 10
}

variable "lock_duration" {
  description = "Lock duration for peek-lock receive (ISO 8601)"
  type        = string
  default     = "PT1M"
}

variable "default_message_ttl" {
  description = "Default message time-to-live (ISO 8601)"
  type        = string
  default     = "P14D"
}

variable "max_size_in_megabytes" {
  description = "Max queue size in MB"
  type        = number
  default     = 1024
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
