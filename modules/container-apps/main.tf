# -----------------------------------------------------------------------------
# Container Apps Module
# -----------------------------------------------------------------------------

# Placeholder image used when no custom image is specified
# This allows Container Apps to deploy successfully before real images are pushed
locals {
  placeholder_image = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
}

resource "azurerm_container_app_environment" "main" {
  name                           = var.environment_name
  location                       = var.location
  resource_group_name            = var.resource_group_name
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  infrastructure_subnet_id       = var.infrastructure_subnet_id
  internal_load_balancer_enabled = var.internal_load_balancer_enabled
  tags                           = var.tags
}

# -----------------------------------------------------------------------------
# Azure Files Storage for Persistent Volumes
# -----------------------------------------------------------------------------

resource "azurerm_container_app_environment_storage" "shares" {
  for_each                     = var.azure_file_shares
  name                         = each.key
  container_app_environment_id = azurerm_container_app_environment.main.id
  account_name                 = var.storage_account_name
  share_name                   = each.value.share_name
  access_key                   = var.storage_account_key
  access_mode                  = each.value.access_mode
}

resource "azurerm_container_app" "apps" {
  for_each                     = { for app in var.apps : app.name => app }
  name                         = each.value.name
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group_name
  revision_mode                = each.value.revision_mode

  identity {
    type = "SystemAssigned"
  }

  # Only configure ACR registry when the image is actually hosted in ACR
  dynamic "registry" {
    for_each = each.value.image != null && var.acr_login_server != null && startswith(each.value.image, "${var.acr_login_server}/") ? [1] : []
    content {
      server   = var.acr_login_server
      identity = "system"
    }
  }

  template {
    min_replicas = each.value.min_replicas
    max_replicas = each.value.max_replicas

    # Volume definitions for Azure Files
    dynamic "volume" {
      for_each = each.value.volume_mounts != null ? each.value.volume_mounts : []
      content {
        name         = volume.value.name
        storage_type = "AzureFile"
        storage_name = volume.value.name
      }
    }

    container {
      name   = each.value.name
      # Use placeholder image if no custom image specified
      # This allows infrastructure to deploy before application images are pushed
      image  = each.value.image != null ? each.value.image : local.placeholder_image
      cpu    = each.value.cpu
      memory = each.value.memory

      dynamic "env" {
        for_each = each.value.env_vars != null ? each.value.env_vars : {}
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = each.value.secret_refs != null ? each.value.secret_refs : {}
        content {
          name        = env.key
          secret_name = env.value
        }
      }

      # Volume mounts for persistent storage
      dynamic "volume_mounts" {
        for_each = each.value.volume_mounts != null ? each.value.volume_mounts : []
        content {
          name = volume_mounts.value.name
          path = volume_mounts.value.mount_path
        }
      }

      # Only add liveness probe if using a custom image (placeholder doesn't have custom health endpoints)
      dynamic "liveness_probe" {
        for_each = each.value.image != null && each.value.health_check_path != null ? [1] : []
        content {
          path             = each.value.health_check_path
          port             = each.value.target_port
          transport        = "HTTP"
          initial_delay    = 10
          interval_seconds = 30
        }
      }
    }
  }

  dynamic "ingress" {
    for_each = each.value.ingress_enabled ? [1] : []
    content {
      external_enabled = each.value.external_ingress
      # Placeholder image runs on port 80, use custom port only when custom image is specified
      target_port      = each.value.image != null ? each.value.target_port : 80
      transport        = "http"
      traffic_weight {
        percentage      = 100
        latest_revision = true
      }
    }
  }

  dynamic "secret" {
    for_each = each.value.secrets != null ? each.value.secrets : {}
    content {
      name  = secret.key
      value = secret.value
    }
  }

  dynamic "secret" {
    for_each = each.value.keyvault_secrets != null ? each.value.keyvault_secrets : {}
    content {
      name                = secret.key
      identity            = "system"
      key_vault_secret_id = secret.value
    }
  }

  tags = var.tags

  lifecycle {
    # Ignore changes to image and ingress port after initial deployment
    # These will be updated when real application images are pushed
    ignore_changes = [
      template[0].container[0].image,
      ingress[0].target_port
    ]
  }

  # Ensure storage is created before apps that use volumes
  depends_on = [azurerm_container_app_environment_storage.shares]
}
