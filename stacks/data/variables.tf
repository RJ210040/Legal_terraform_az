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

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "postgresql_sku" {
  description = "PostgreSQL SKU"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "postgresql_storage_mb" {
  description = "PostgreSQL storage in MB"
  type        = number
  default     = 32768
}

variable "postgresql_ha_enabled" {
  description = "Enable PostgreSQL high availability"
  type        = bool
  default     = false
}

variable "databases" {
  description = "List of databases to create"
  type        = list(string)
  default     = ["legal"]
}

variable "postgresql_extensions" {
  description = "PostgreSQL extensions"
  type        = list(string)
  default     = ["uuid-ossp", "pgcrypto"]
}

variable "storage_replication_type" {
  description = "Storage replication type"
  type        = string
  default     = "LRS"
}

variable "storage_containers" {
  description = "Storage containers to create"
  type        = list(string)
  default     = ["evidence", "audit-packs"]
}

variable "enable_versioning" {
  description = "Enable blob versioning for evidence traceability"
  type        = bool
  default     = true
}

variable "blob_soft_delete_days" {
  description = "Blob soft delete retention days"
  type        = number
  default     = 30
}

variable "backup_retention_days" {
  description = "PostgreSQL backup retention days"
  type        = number
  default     = 7
}

variable "servicebus_sku" {
  description = "Service Bus namespace SKU"
  type        = string
  default     = "Standard"
}

variable "servicebus_queues" {
  description = "Service Bus queues to create"
  type        = list(string)
  default     = ["evidence-validation", "evidence-notification"]
}

variable "postgresql_firewall_rules" {
  description = "PostgreSQL firewall rules for public access mode"
  type = list(object({
    name     = string
    start_ip = string
    end_ip   = string
  }))
  default = [
    {
      name     = "AllowAzureServices"
      start_ip = "0.0.0.0"
      end_ip   = "0.0.0.0"
    }
  ]
}

variable "enable_private_endpoints" {
  description = "Enable private endpoints"
  type        = bool
  default     = true
}

variable "storage_file_shares" {
  description = "List of Azure File shares to create in the storage account"
  type        = list(string)
  default     = []
}
