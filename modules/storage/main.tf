# -----------------------------------------------------------------------------
# Storage Module
# -----------------------------------------------------------------------------

resource "azurerm_storage_account" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  account_tier              = var.account_tier
  account_replication_type  = var.replication_type
  account_kind              = "StorageV2"
  access_tier               = var.access_tier
  min_tls_version            = "TLS1_2"
  https_traffic_only_enabled = true

  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true
  public_network_access_enabled   = var.public_network_access_enabled

  blob_properties {
    versioning_enabled = var.enable_versioning
    dynamic "delete_retention_policy" {
      for_each = var.blob_soft_delete_days > 0 ? [1] : []
      content {
        days = var.blob_soft_delete_days
      }
    }
  }

  network_rules {
    default_action             = var.public_network_access_enabled ? "Allow" : "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

  tags = var.tags
}

resource "azurerm_storage_container" "containers" {
  for_each             = toset(var.containers)
  name                 = each.value
  storage_account_id   = azurerm_storage_account.main.id
  container_access_type = "private"
}

resource "azurerm_storage_share" "shares" {
  for_each           = toset(var.file_shares)
  name               = each.value
  storage_account_id = azurerm_storage_account.main.id
  quota              = var.file_share_quota_gb
}

resource "azurerm_private_endpoint" "blob" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.name}-blob-pep"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name}-blob-psc"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }

  tags = var.tags
}
