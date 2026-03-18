variable "name" {
  description = "PostgreSQL server name"
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

variable "administrator_login" {
  description = "Administrator login name"
  type        = string
  default     = "pgadmin"
}

variable "administrator_password" {
  description = "Administrator password (auto-generated if null)"
  type        = string
  default     = null
  sensitive   = true
}

variable "sku_name" {
  description = "SKU name"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "16"
}

variable "storage_mb" {
  description = "Storage size in MB"
  type        = number
  default     = 32768
}

variable "delegated_subnet_id" {
  description = "Delegated subnet ID for VNet integration"
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID"
  type        = string
  default     = null
}

variable "backup_retention_days" {
  description = "Backup retention days"
  type        = number
  default     = 7
}

variable "geo_redundant_backup_enabled" {
  description = "Enable geo-redundant backup"
  type        = bool
  default     = false
}

variable "ha_enabled" {
  description = "Enable high availability"
  type        = bool
  default     = false
}

variable "availability_zone" {
  description = "Availability zone"
  type        = string
  default     = "1"
}

variable "standby_availability_zone" {
  description = "Standby availability zone for HA"
  type        = string
  default     = "2"
}

variable "databases" {
  description = "List of databases to create"
  type        = list(string)
  default     = ["agentic"]
}

variable "extensions" {
  description = "PostgreSQL extensions to enable"
  type        = list(string)
  default     = ["uuid-ossp", "pgcrypto"]
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
