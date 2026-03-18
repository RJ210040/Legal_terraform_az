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

variable "container_apps" {
  description = "Container apps configuration"
  type = list(object({
    name                            = string
    image                           = optional(string)
    cpu                             = optional(number, 0.5)
    memory                          = optional(string, "1Gi")
    min_replicas                    = optional(number, 0)
    max_replicas                    = optional(number, 2)
    target_port                     = optional(number, 8080)
    ingress_enabled                 = optional(bool, true)
    external_ingress                = optional(bool, true)
    health_check_path               = optional(string)
    env_vars                        = optional(map(string), {})
    secret_refs                     = optional(map(string), {})
    secrets                         = optional(map(string), {})
    keyvault_secrets                = optional(map(string), {})
    revision_mode                   = optional(string, "Single")
    enable_http_scaling             = optional(bool, true)
    concurrent_requests_per_replica = optional(number, 100)
    volume_mounts = optional(list(object({
      name       = string
      mount_path = string
    })), [])
  }))
  default = [
    {
      name              = "fastapi-backend"
      cpu               = 0.5
      memory            = "1Gi"
      min_replicas      = 0
      max_replicas      = 2
      target_port       = 8000
      health_check_path = "/health"
    },
    {
      name         = "react-frontend"
      cpu          = 0.5
      memory       = "1Gi"
      min_replicas = 0
      max_replicas = 2
      target_port  = 3000
    }
  ]
}

variable "azure_file_shares" {
  description = "Map of Azure File share configurations for persistent storage"
  type = map(object({
    share_name  = string
    access_mode = optional(string, "ReadWrite")
  }))
  default = {}
}
