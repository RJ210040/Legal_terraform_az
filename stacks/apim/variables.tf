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

variable "enable_apim" {
  description = "Deploy Azure API Management gateway"
  type        = bool
  default     = true
}

variable "publisher_name" {
  description = "Publisher name"
  type        = string
  default     = "TV Engineering"
}

variable "publisher_email" {
  description = "Publisher email"
  type        = string
  default     = "infra@tresvista.com"
}

variable "sku_name" {
  description = "APIM SKU"
  type        = string
  default     = "Consumption_0"
}

variable "products" {
  description = "API products"
  type = list(object({
    id                    = string
    display_name          = string
    description           = optional(string, "")
    subscription_required = optional(bool, true)
    approval_required     = optional(bool, false)
    published             = optional(bool, true)
  }))
  default = [
    {
      id           = "ai-services"
      display_name = "AI Services"
      description  = "Azure OpenAI and Perplexity APIs"
    }
  ]
}

variable "apis" {
  description = "APIs"
  type = list(object({
    name         = string
    display_name = string
    path         = string
    backend_url  = string
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
  default     = null # Set per environment in tfvars
}
