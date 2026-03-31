variable "environment_name" {
  description = "Container Apps environment name"
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

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  type        = string
}

variable "infrastructure_subnet_id" {
  description = "Infrastructure subnet ID"
  type        = string
}

variable "internal_load_balancer_enabled" {
  description = "Enable internal load balancer"
  type        = bool
  default     = false
}

variable "acr_login_server" {
  description = "ACR login server URL"
  type        = string
  default     = null
}

variable "apps" {
  description = "List of container apps to deploy"
  type = list(object({
    name                            = string
    image                           = optional(string)
    cpu                             = optional(number, 0.5)
    memory                          = optional(string, "1Gi")
    min_replicas                    = optional(number, 0)
    max_replicas                    = optional(number, 2)
    revision_mode                   = optional(string, "Single")
    target_port                     = optional(number, 8080)
    ingress_enabled                 = optional(bool, true)
    external_ingress                = optional(bool, true)
    health_check_path               = optional(string)
    enable_http_scaling             = optional(bool, true)
    concurrent_requests_per_replica = optional(number, 100)
    env_vars                        = optional(map(string), {})
    secret_refs                     = optional(map(string), {})
    secrets                         = optional(map(string), {})
    keyvault_secrets                = optional(map(string), {})
    # Volume mount configuration (optional)
    volume_mounts = optional(list(object({
      name       = string
      mount_path = string
    })), [])
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Azure Files Storage (for persistent volumes)
# -----------------------------------------------------------------------------

variable "storage_account_name" {
  description = "Storage account name for Azure Files volumes"
  type        = string
  default     = null
}

variable "storage_account_key" {
  description = "Storage account access key for Azure Files volumes"
  type        = string
  default     = null
  sensitive   = true
}

variable "azure_file_shares" {
  description = "Map of Azure File share configurations for persistent storage"
  type = map(object({
    share_name  = string
    access_mode = optional(string, "ReadWrite")
  }))
  default = {}
}

variable "allowed_source_ips" {
  description = "List of allowed source IP CIDR ranges for Container Apps ingress. Empty list allows all traffic."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
