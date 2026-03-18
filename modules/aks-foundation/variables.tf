variable "name" {
  description = "AKS cluster name"
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

variable "dns_prefix" {
  description = "DNS prefix"
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "subnet_id" {
  description = "Subnet ID for nodes"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "system_nodepool" {
  description = "System node pool configuration"
  type = object({
    vm_size             = optional(string, "Standard_D4s_v5")
    node_count          = optional(number, 2)
    min_count           = optional(number, 2)
    max_count           = optional(number, 5)
    enable_auto_scaling = optional(bool, true)
    os_disk_size_gb     = optional(number, 128)
  })
  default = {}
}

variable "user_nodepools" {
  description = "User node pool configurations"
  type = list(object({
    name                = string
    vm_size             = optional(string, "Standard_E4s_v5")
    node_count          = optional(number, 3)
    min_count           = optional(number, 3)
    max_count           = optional(number, 6)
    enable_auto_scaling = optional(bool, true)
    os_disk_size_gb     = optional(number, 128)
    node_labels         = optional(map(string), {})
    node_taints         = optional(list(string), [])
  }))
  default = []
}

variable "network_plugin" {
  description = "Network plugin"
  type        = string
  default     = "azure"
}

variable "network_policy" {
  description = "Network policy"
  type        = string
  default     = "azure"
}

variable "service_cidr" {
  description = "Service CIDR"
  type        = string
  default     = "10.1.0.0/16"
}

variable "dns_service_ip" {
  description = "DNS service IP"
  type        = string
  default     = "10.1.0.10"
}

variable "enable_oidc_issuer" {
  description = "Enable OIDC issuer"
  type        = bool
  default     = true
}

variable "enable_workload_identity" {
  description = "Enable workload identity"
  type        = bool
  default     = true
}

variable "enable_azure_rbac" {
  description = "Enable Azure AD RBAC"
  type        = bool
  default     = true
}

variable "enable_key_vault_secrets_provider" {
  description = "Enable Key Vault secrets provider"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  type        = string
  default     = null
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
