# -----------------------------------------------------------------------------
# APIM Stack
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.66"
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

data "terraform_remote_state" "foundation" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.state_resource_group_name
    storage_account_name = var.state_storage_account_name
    container_name       = var.state_container_name
    key                  = "foundation.tfstate"
  }
}
data "terraform_remote_state" "monitor" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.state_resource_group_name
    storage_account_name = var.state_storage_account_name
    container_name       = var.state_container_name
    key                  = "monitor.tfstate"
  }
}

locals {
  rg_name     = data.terraform_remote_state.foundation.outputs.resource_group_name
  location    = data.terraform_remote_state.foundation.outputs.location
  naming      = data.terraform_remote_state.foundation.outputs.naming
  common_tags = data.terraform_remote_state.foundation.outputs.common_tags
}

module "apim" {
  count               = var.enable_apim ? 1 : 0
  source              = "../../modules/apim"
  name                = local.naming.api_management
  location            = local.location
  resource_group_name = local.rg_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.sku_name
  products            = var.products
  apis                = var.apis
  api_product_links   = var.api_product_links
  global_policy       = var.global_policy
  tags                = local.common_tags
}
