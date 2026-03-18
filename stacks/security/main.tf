# -----------------------------------------------------------------------------
# Security Stack - Key Vault + Managed Identities
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
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
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
  rg_id       = data.terraform_remote_state.foundation.outputs.resource_group_id
  location    = data.terraform_remote_state.foundation.outputs.location
  naming      = data.terraform_remote_state.foundation.outputs.naming
  common_tags = data.terraform_remote_state.foundation.outputs.common_tags
  subnet_ids  = data.terraform_remote_state.network.outputs.subnet_ids
  dns_zones   = data.terraform_remote_state.network.outputs.private_dns_zone_ids

  keyvault_external_secrets = {
    for k, v in {
      "azure-openai-api-key" = var.azure_openai_api_key
      "perplexity-api-key"   = var.perplexity_api_key
    } : k => v if v != ""
  }
}

resource "azurerm_user_assigned_identity" "workload" {
  name                = local.naming.managed_identity
  location            = local.location
  resource_group_name = local.rg_name
  tags                = local.common_tags
}

module "keyvault" {
  source                     = "../../modules/keyvault"
  name                       = local.naming.key_vault
  location                   = local.location
  resource_group_name        = local.rg_name
  enable_private_endpoint    = var.enable_private_endpoints
  private_endpoint_subnet_id = local.subnet_ids.pep
  private_dns_zone_id        = lookup(local.dns_zones, "keyvault", null)
  generate_secrets = {
    "postgresql-admin-password" = {
      length  = 32
      special = true
    }
  }
  external_secrets = local.keyvault_external_secrets
  tags                       = local.common_tags
}

resource "azurerm_role_assignment" "workload_kv" {
  scope                = module.keyvault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
}

# ---------------------------------------------------------------------------
# Developer Access - grants team members access to Azure resources
# ---------------------------------------------------------------------------

resource "azurerm_role_assignment" "developer_rg" {
  for_each             = var.developer_object_ids
  scope                = local.rg_id
  role_definition_name = "Contributor"
  principal_id         = each.value
  principal_type       = "User"
}

resource "azurerm_role_assignment" "developer_kv" {
  for_each             = var.developer_object_ids
  scope                = module.keyvault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value
  principal_type       = "User"
}
