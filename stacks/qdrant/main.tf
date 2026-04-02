# -----------------------------------------------------------------------------
# Qdrant Stack - Container Apps (dev) or AKS (prod)
# 
# Dev: Qdrant runs as a Container App (deployed via compute-aca stack)
#      This stack only references the endpoint for outputs
# Prod: Qdrant runs on AKS via Helm
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.66"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.36"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
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
data "terraform_remote_state" "compute_aca" {
  count   = contains(["dev", "mvp"], var.environment) ? 1 : 0
  backend = "azurerm"
  config = {
    resource_group_name  = var.state_resource_group_name
    storage_account_name = var.state_storage_account_name
    container_name       = var.state_container_name
    key                  = "compute-aca.tfstate"
  }
}
data "terraform_remote_state" "aks" {
  count   = var.environment == "prod" ? 1 : 0
  backend = "azurerm"
  config = {
    resource_group_name  = var.state_resource_group_name
    storage_account_name = var.state_storage_account_name
    container_name       = var.state_container_name
    key                  = "compute-aks.tfstate"
  }
}

locals {
  rg_name     = data.terraform_remote_state.foundation.outputs.resource_group_name
  location    = data.terraform_remote_state.foundation.outputs.location
  naming      = data.terraform_remote_state.foundation.outputs.naming
  common_tags = data.terraform_remote_state.foundation.outputs.common_tags
  subnet_ids  = data.terraform_remote_state.network.outputs.subnet_ids
}

# Kubernetes provider (prod only)
data "azurerm_kubernetes_cluster" "aks" {
  count               = var.environment == "prod" ? 1 : 0
  name                = data.terraform_remote_state.aks[0].outputs.cluster_name
  resource_group_name = local.rg_name
}

locals {
  # try() handles the dev case where count = 0 and aks[0] does not exist.
  # Extracting the whole kube_config object here keeps base64decode() calls
  # in the provider blocks simple and avoids nested try(base64decode(...)) warnings.
  _aks_cfg = try(data.azurerm_kubernetes_cluster.aks[0].kube_config[0], null)
}

provider "kubernetes" {
  host                   = local._aks_cfg != null ? local._aks_cfg.host : null
  client_certificate     = local._aks_cfg != null ? base64decode(local._aks_cfg.client_certificate) : null
  client_key             = local._aks_cfg != null ? base64decode(local._aks_cfg.client_key) : null
  cluster_ca_certificate = local._aks_cfg != null ? base64decode(local._aks_cfg.cluster_ca_certificate) : null
}

provider "helm" {
  kubernetes {
    host                   = local._aks_cfg != null ? local._aks_cfg.host : null
    client_certificate     = local._aks_cfg != null ? base64decode(local._aks_cfg.client_certificate) : null
    client_key             = local._aks_cfg != null ? base64decode(local._aks_cfg.client_key) : null
    cluster_ca_certificate = local._aks_cfg != null ? base64decode(local._aks_cfg.cluster_ca_certificate) : null
  }
}

# -----------------------------------------------------------------------------
# Dev: Qdrant runs on Container Apps (deployed via compute-aca stack)
# We just reference the endpoint here for outputs
# -----------------------------------------------------------------------------
locals {
  # For dev, get Qdrant FQDN from Container Apps.
  # try() guards against the count=0 case (prod) where compute_aca[0] does not exist.
  qdrant_aca_fqdn = try(
    lookup(data.terraform_remote_state.compute_aca[0].outputs.app_fqdns, "qdrant", null),
    null
  )
}

# Qdrant on AKS (prod only, and only when enable_qdrant = true)
module "qdrant_aks" {
  source           = "../../modules/qdrant-aks"
  count            = var.enable_qdrant && var.environment == "prod" ? 1 : 0
  release_name     = "qdrant"
  namespace        = "qdrant"
  replicas         = var.aks_replicas
  resources        = var.aks_resources
  persistence      = var.aks_persistence
  node_selector    = { "workload" = "qdrant" }
  enable_hpa       = var.enable_hpa
  hpa_min_replicas = var.hpa_min_replicas
  hpa_max_replicas = var.hpa_max_replicas
  depends_on       = [data.azurerm_kubernetes_cluster.aks]
}
