variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "vnet_name" {
  description = "Virtual network name"
  type        = string
}

variable "address_space" {
  description = "VNet address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_names" {
  description = "Subnet names"
  type = object({
    aca  = string
    aks  = string
    data = string
    pep  = string
    apim = string
    aci  = string
  })
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

variable "nsg_name_prefix" {
  description = "NSG name prefix"
  type        = string
}

variable "enable_aks_subnet" {
  description = "Create AKS subnet"
  type        = bool
  default     = false
}

variable "enable_aci_subnet" {
  description = "Create ACI subnet"
  type        = bool
  default     = true
}

variable "enable_private_dns" {
  description = "Create private DNS zones"
  type        = bool
  default     = true
}

variable "private_dns_zones" {
  description = "Private DNS zone names"
  type        = map(string)
  default = {
    acr        = "privatelink.azurecr.io"
    postgres   = "privatelink.postgres.database.azure.com"
    keyvault   = "privatelink.vaultcore.azure.net"
    blob       = "privatelink.blob.core.windows.net"
    openai     = "privatelink.openai.azure.com"
    servicebus = "privatelink.servicebus.windows.net"
  }
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
