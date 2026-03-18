variable "name" {
  description = "Container instance name"
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

variable "qdrant_image" {
  description = "Qdrant Docker image"
  type        = string
  default     = "qdrant/qdrant:latest"
}

variable "cpu" {
  description = "CPU cores"
  type        = number
  default     = 2
}

variable "memory_gb" {
  description = "Memory in GB"
  type        = number
  default     = 4
}

variable "subnet_id" {
  description = "Subnet ID for VNet integration"
  type        = string
  default     = null
}

variable "storage_account_name" {
  description = "Storage account name for persistence"
  type        = string
  default     = null
}

variable "storage_account_key" {
  description = "Storage account key"
  type        = string
  default     = null
  sensitive   = true
}

variable "file_share_name" {
  description = "File share name for persistence"
  type        = string
  default     = "qdrant-data"
}

variable "environment_variables" {
  description = "Environment variables"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
