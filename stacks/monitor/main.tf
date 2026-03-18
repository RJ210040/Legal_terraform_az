# -----------------------------------------------------------------------------
# Monitor Stack
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

locals {
  rg_name     = data.terraform_remote_state.foundation.outputs.resource_group_name
  location    = data.terraform_remote_state.foundation.outputs.location
  naming      = data.terraform_remote_state.foundation.outputs.naming
  common_tags = data.terraform_remote_state.foundation.outputs.common_tags
}

module "monitor" {
  source                    = "../../modules/monitor"
  workspace_name            = local.naming.log_analytics_workspace
  app_insights_name         = local.naming.application_insights
  location                  = local.location
  resource_group_name       = local.rg_name
  retention_in_days         = var.retention_in_days
  daily_quota_gb            = var.daily_quota_gb
  enable_container_insights = var.enable_container_insights
  tags                      = local.common_tags
}
