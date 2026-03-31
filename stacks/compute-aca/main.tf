# -----------------------------------------------------------------------------
# Compute ACA Stack
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

  # ── Database containers — controlled entirely by feature flags ────────────
  # These are NOT defined in terraform.tfvars. Setting enable_qdrant/enable_neo4j
  # to true is the only action required to deploy them.
  #
  # min_replicas = 1: database containers must never scale to zero.
  # Qdrant: querying an unstarted container loses the connection.
  # Neo4j: takes 60-90s to initialise — unacceptable cold-start latency.

  _qdrant_app = {
    name                            = "qdrant"
    image                           = "qdrant/qdrant:v1.13.2"
    cpu                             = 1.0
    memory                          = "2Gi"
    min_replicas                    = 1
    max_replicas                    = 1
    revision_mode                   = "Single"
    target_port                     = 6333
    ingress_enabled                 = true
    external_ingress                = true
    health_check_path               = "/healthz"
    enable_http_scaling             = false
    concurrent_requests_per_replica = 100
    env_vars                        = { "QDRANT__SERVICE__GRPC_PORT" = "6334" }
    secret_refs                     = {}
    secrets                         = {}
    keyvault_secrets                = {}
    volume_mounts                   = [{ name = "qdrant-data", mount_path = "/qdrant/storage" }]
  }

  _neo4j_app = {
    name                            = "neo4j"
    image                           = "neo4j:5"
    cpu                             = 1.0
    memory                          = "2Gi"
    min_replicas                    = 1
    max_replicas                    = 1
    revision_mode                   = "Single"
    target_port                     = 7474
    ingress_enabled                 = true
    external_ingress                = true
    health_check_path               = null
    enable_http_scaling             = false
    concurrent_requests_per_replica = 100
    env_vars = {
      "NEO4J_AUTH"                             = "none"
      "NEO4J_server_default__listen__address"  = "0.0.0.0"
      "NEO4J_server_memory_heap_initial__size" = "512m"
      "NEO4J_server_memory_heap_max__size"     = "1G"
      "NEO4J_server_memory_pagecache__size"    = "512m"
    }
    secret_refs      = {}
    secrets          = {}
    keyvault_secrets = {}
    volume_mounts    = [{ name = "neo4j-data", mount_path = "/data" }]
  }

  # Final app list: user-defined apps + flag-controlled database containers
  effective_apps = concat(
    var.container_apps,
    var.enable_qdrant ? [local._qdrant_app] : [],
    var.enable_neo4j  ? [local._neo4j_app]  : []
  )

  # Azure Files shares: auto-derived from feature flags + any user-defined extras
  effective_file_shares = merge(
    var.azure_file_shares,
    var.enable_qdrant ? { "qdrant-data" = { share_name = "qdrant-data", access_mode = "ReadWrite" } } : {},
    var.enable_neo4j  ? { "neo4j-data"  = { share_name = "neo4j-data",  access_mode = "ReadWrite" } } : {}
  )
}

module "container_apps" {
  source                     = "../../modules/container-apps"
  environment_name           = local.naming.container_app_environment
  location                   = local.location
  resource_group_name        = local.rg_name
  log_analytics_workspace_id = local.workspace_id
  infrastructure_subnet_id   = local.subnet_ids.aca
  acr_login_server           = local.acr_login_server
  apps                       = local.effective_apps
  storage_account_name       = local.storage_account_name
  storage_account_key        = local.storage_access_key
  azure_file_shares          = local.effective_file_shares
  allowed_source_ips         = var.allowed_source_ips
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
