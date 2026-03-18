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

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "system_nodepool" {
  description = "System node pool configuration"
  type = object({
    vm_size             = optional(string, "Standard_D4s_v5")
    min_count           = optional(number, 2)
    max_count           = optional(number, 5)
    enable_auto_scaling = optional(bool, true)
  })
  default = {}
}

variable "user_nodepools" {
  description = "User node pool configurations"
  type = list(object({
    name                = string
    vm_size             = optional(string, "Standard_E4s_v5")
    min_count           = optional(number, 3)
    max_count           = optional(number, 6)
    enable_auto_scaling = optional(bool, true)
    node_labels         = optional(map(string), {})
    node_taints         = optional(list(string), [])
  }))
  default = [
    {
      name        = "qdrant"
      vm_size     = "Standard_E4s_v5"
      node_labels = { "workload" = "qdrant" }
      node_taints = ["workload=qdrant:NoSchedule"]
    }
  ]
}
