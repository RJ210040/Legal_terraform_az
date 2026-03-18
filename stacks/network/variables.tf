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

variable "address_space" {
  description = "VNet address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_cidrs" {
  description = "Subnet CIDR blocks"
  type = object({
    aca  = string
    aks  = string
    data = string
    pep  = string
    apim = string
    aci  = string
  })
  default = {
    aca  = "10.0.1.0/24"
    aks  = "10.0.2.0/24"
    data = "10.0.3.0/24"
    pep  = "10.0.4.0/24"
    apim = "10.0.5.0/24"
    aci  = "10.0.6.0/24"
  }
}

variable "enable_private_dns" {
  description = "Create private DNS zones"
  type        = bool
  default     = true
}
