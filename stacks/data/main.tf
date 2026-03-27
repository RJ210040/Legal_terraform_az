# -----------------------------------------------------------------------------
# Data Stack - PostgreSQL + Storage
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
data "terraform_remote_state" "security" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.state_resource_group_name
    storage_account_name = var.state_storage_account_name
    container_name       = var.state_container_name
    key                  = "security.tfstate"
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

module "postgres" {
  source               = "../../modules/postgres"
  name                 = local.naming.postgresql_server
  location             = local.location
  resource_group_name  = local.rg_name
  sku_name             = var.postgresql_sku
  storage_mb           = var.postgresql_storage_mb
  ha_enabled           = var.postgresql_ha_enabled
  backup_retention_days = var.backup_retention_days
  delegated_subnet_id  = var.enable_private_endpoints ? local.subnet_ids.data : null
  private_dns_zone_id  = var.enable_private_endpoints ? lookup(local.dns_zones, "postgres", null) : null
  firewall_rules       = var.enable_private_endpoints ? [] : var.postgresql_firewall_rules
  databases            = var.databases
  extensions           = var.postgresql_extensions
  tags                 = local.common_tags
}

module "storage" {
  source                     = "../../modules/storage"
  name                       = local.naming.storage_account
  location                   = local.location
  resource_group_name        = local.rg_name
  replication_type           = var.storage_replication_type
  containers                 = var.storage_containers
  file_shares                = var.storage_file_shares
  enable_versioning          = var.enable_versioning
  blob_soft_delete_days      = var.blob_soft_delete_days
  enable_private_endpoint    = var.enable_private_endpoints
  private_endpoint_subnet_id = local.subnet_ids.pep
  private_dns_zone_id        = lookup(local.dns_zones, "blob", null)
  tags                       = local.common_tags
}

module "servicebus" {
  source                     = "../../modules/service-bus"
  name                       = local.naming.service_bus_namespace
  location                   = local.location
  resource_group_name        = local.rg_name
  sku                        = var.servicebus_sku
  queues                     = var.servicebus_queues
  enable_private_endpoint    = var.servicebus_sku == "Premium" ? var.enable_private_endpoints : false
  private_endpoint_subnet_id = local.subnet_ids.pep
  private_dns_zone_id        = lookup(local.dns_zones, "servicebus", null)
  tags                       = local.common_tags
}

data "azurerm_key_vault" "main" {
  name                = data.terraform_remote_state.security.outputs.keyvault_name
  resource_group_name = local.rg_name
}

resource "azurerm_key_vault_secret" "pg_conn" {
  name         = "postgresql-connection-string"
  value        = module.postgres.connection_string_full
  key_vault_id = data.azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "sb_conn" {
  name         = "servicebus-connection-string"
  value        = module.servicebus.primary_connection_string
  key_vault_id = data.azurerm_key_vault.main.id
}
