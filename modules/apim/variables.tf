variable "name" {
  description = "API Management name"
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

variable "publisher_name" {
  description = "Publisher name"
  type        = string
}

variable "publisher_email" {
  description = "Publisher email"
  type        = string
}

variable "sku_name" {
  description = "SKU name"
  type        = string
  default     = "Consumption_0"
}

variable "products" {
  description = "List of API products"
  type = list(object({
    id                    = string
    display_name          = string
    description           = optional(string, "")
    subscription_required = optional(bool, true)
    approval_required     = optional(bool, false)
    published             = optional(bool, true)
  }))
  default = []
}

variable "apis" {
  description = "List of APIs"
  type = list(object({
    name         = string
    display_name = string
    path         = string
    backend_url  = string
    revision     = optional(string, "1")
    protocols    = optional(list(string), ["https"])
  }))
  default = []
}

variable "api_product_links" {
  description = "API to product mappings"
  type = list(object({
    api_name   = string
    product_id = string
  }))
  default = []
}

variable "global_policy" {
  description = "Global XML policy"
  type        = string
  default     = null
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
