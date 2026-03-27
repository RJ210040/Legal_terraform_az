# -----------------------------------------------------------------------------
# Network Stack
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

locals {
  rg_name     = data.terraform_remote_state.foundation.outputs.resource_group_name
  location    = data.terraform_remote_state.foundation.outputs.location
  naming      = data.terraform_remote_state.foundation.outputs.naming
  common_tags = data.terraform_remote_state.foundation.outputs.common_tags
  subnets     = data.terraform_remote_state.foundation.outputs.subnets
}

module "network" {
  source              = "../../modules/network"
  resource_group_name = local.rg_name
  location            = local.location
  vnet_name           = local.naming.virtual_network
  nsg_name_prefix     = local.naming.network_security_group
  address_space       = var.address_space
  subnet_names        = local.subnets
  subnet_cidrs        = var.subnet_cidrs
  enable_aks_subnet   = var.environment == "prod"
  enable_aci_subnet   = var.environment == "dev"
  enable_private_dns  = var.enable_private_dns
  tags                = local.common_tags
}
