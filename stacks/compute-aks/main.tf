# -----------------------------------------------------------------------------
# Compute AKS Stack (prod only)
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
data "terraform_remote_state" "network" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.state_resource_group_name
    storage_account_name = var.state_storage_account_name
    container_name       = var.state_container_name
    key                  = "network.tfstate"
  }
}
data "terraform_remote_state" "registry" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.state_resource_group_name
    storage_account_name = var.state_storage_account_name
    container_name       = var.state_container_name
    key                  = "registry.tfstate"
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
  rg_name      = data.terraform_remote_state.foundation.outputs.resource_group_name
  location     = data.terraform_remote_state.foundation.outputs.location
  naming       = data.terraform_remote_state.foundation.outputs.naming
  common_tags  = data.terraform_remote_state.foundation.outputs.common_tags
  subnet_ids   = data.terraform_remote_state.network.outputs.subnet_ids
  acr_id       = data.terraform_remote_state.registry.outputs.acr_id
  workspace_id = data.terraform_remote_state.monitor.outputs.workspace_id
}

module "aks" {
  count                      = var.enable_aks ? 1 : 0
  source                     = "../../modules/aks-foundation"
  name                       = local.naming.kubernetes_cluster
  location                   = local.location
  resource_group_name        = local.rg_name
  subnet_id                  = local.subnet_ids.aks
  kubernetes_version         = var.kubernetes_version
  system_nodepool            = var.system_nodepool
  user_nodepools             = var.user_nodepools
  log_analytics_workspace_id = local.workspace_id
  tags                       = local.common_tags
}

resource "azurerm_role_assignment" "aks_acr" {
  count                = var.enable_aks ? 1 : 0
  scope                = local.acr_id
  role_definition_name = "AcrPull"
  principal_id         = module.aks[0].kubelet_identity_object_id
}
