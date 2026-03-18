# -----------------------------------------------------------------------------
# Registry Stack - ACR
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100.0"
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

data "terraform_remote_state" "network" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.state_resource_group_name
    storage_account_name = var.state_storage_account_name
    container_name       = var.state_container_name
    key                  = "network.tfstate"
  }
}

locals {
  rg_name     = data.terraform_remote_state.foundation.outputs.resource_group_name
  location    = data.terraform_remote_state.foundation.outputs.location
  naming      = data.terraform_remote_state.foundation.outputs.naming
  common_tags = data.terraform_remote_state.foundation.outputs.common_tags
  subnet_ids  = data.terraform_remote_state.network.outputs.subnet_ids
  dns_zones   = data.terraform_remote_state.network.outputs.private_dns_zone_ids
}

module "acr" {
  source                     = "../../modules/acr"
  name                       = local.naming.container_registry
  location                   = local.location
  resource_group_name        = local.rg_name
  sku                        = var.acr_sku
  geo_replications           = var.geo_replications
  enable_private_endpoint    = var.enable_private_endpoints
  private_endpoint_subnet_id = local.subnet_ids.pep
  private_dns_zone_id        = lookup(local.dns_zones, "acr", null)
  tags                       = local.common_tags
}
