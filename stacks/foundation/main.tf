# -----------------------------------------------------------------------------
# Foundation Stack - Resource Group and Naming
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
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}

module "naming" {
  source      = "../../modules/naming"
  org_short   = var.org_short
  project     = var.project
  environment = var.environment
  region      = var.region
  sequence    = var.sequence
  extra_tags  = var.extra_tags
}

resource "azurerm_resource_group" "main" {
  name     = module.naming.resource_group
  location = var.region
  tags     = module.naming.common_tags
}
