# -----------------------------------------------------------------------------
# Compute ACA Stack
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
data "terraform_remote_state" "security" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.state_resource_group_name
    storage_account_name = var.state_storage_account_name
    container_name       = var.state_container_name
    key                  = "security.tfstate"
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
data "terraform_remote_state" "data" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.state_resource_group_name
    storage_account_name = var.state_storage_account_name
    container_name       = var.state_container_name
    key                  = "data.tfstate"
  }
}

locals {
  rg_name              = data.terraform_remote_state.foundation.outputs.resource_group_name
  location             = data.terraform_remote_state.foundation.outputs.location
  naming               = data.terraform_remote_state.foundation.outputs.naming
  common_tags          = data.terraform_remote_state.foundation.outputs.common_tags
  subnet_ids           = data.terraform_remote_state.network.outputs.subnet_ids
  keyvault_id          = data.terraform_remote_state.security.outputs.keyvault_id
  acr_login_server     = data.terraform_remote_state.registry.outputs.acr_login_server
  acr_id               = data.terraform_remote_state.registry.outputs.acr_id
  workspace_id         = data.terraform_remote_state.monitor.outputs.workspace_id
  storage_account_name = data.terraform_remote_state.data.outputs.storage_account_name
  storage_access_key   = data.terraform_remote_state.data.outputs.storage_primary_access_key
}

module "container_apps" {
  source                     = "../../modules/container-apps"
  environment_name           = local.naming.container_app_environment
  location                   = local.location
  resource_group_name        = local.rg_name
  log_analytics_workspace_id = local.workspace_id
  infrastructure_subnet_id   = local.subnet_ids.aca
  acr_login_server           = local.acr_login_server
  apps                       = var.container_apps
  # Azure Files storage for persistent volumes (e.g., Qdrant data)
  storage_account_name       = local.storage_account_name
  storage_account_key        = local.storage_access_key
  azure_file_shares          = var.azure_file_shares
  tags                       = local.common_tags
}

module "aca_acr_role" {
  source = "../../modules/role-assignments"
  role_assignments = [for name, pid in module.container_apps.app_identities : {
    name                 = "${name}-acr-pull"  # Static key known at plan time
    scope                = local.acr_id
    role_definition_name = "AcrPull"
    principal_id         = pid
    skip_aad_check       = true
  }]
}

module "aca_kv_role" {
  source = "../../modules/role-assignments"
  role_assignments = [for name, pid in module.container_apps.app_identities : {
    name                 = "${name}-kv-secrets"  # Static key known at plan time
    scope                = local.keyvault_id
    role_definition_name = "Key Vault Secrets User"
    principal_id         = pid
    skip_aad_check       = true
  }]
}
