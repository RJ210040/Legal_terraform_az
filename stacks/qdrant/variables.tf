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

variable "aci_cpu" {
  description = "ACI CPU cores"
  type        = number
  default     = 2
}

variable "aci_memory_gb" {
  description = "ACI memory in GB"
  type        = number
  default     = 4
}

variable "aks_replicas" {
  description = "AKS Qdrant replicas"
  type        = number
  default     = 3
}

variable "aks_resources" {
  description = "AKS resource configuration"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "1000m"
      memory = "4Gi"
    }
    limits = {
      cpu    = "4000m"
      memory = "16Gi"
    }
  }
}

variable "aks_persistence" {
  description = "AKS persistence configuration"
  type = object({
    enabled       = bool
    size          = string
    storage_class = string
  })
  default = {
    enabled       = true
    size          = "100Gi"
    storage_class = "managed-premium"
  }
}

variable "enable_hpa" {
  description = "Enable HPA"
  type        = bool
  default     = true
}

variable "hpa_min_replicas" {
  description = "HPA min replicas"
  type        = number
  default     = 3
}

variable "hpa_max_replicas" {
  description = "HPA max replicas"
  type        = number
  default     = 6
}
