# -----------------------------------------------------------------------------
# Key Vault Module
# -----------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.sku_name

  enabled_for_disk_encryption     = false
  enabled_for_deployment          = false
  enabled_for_template_deployment = false
  rbac_authorization_enabled      = true
  purge_protection_enabled        = var.purge_protection_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days

  public_network_access_enabled = var.public_network_access_enabled

  network_acls {
    bypass                     = "AzureServices"
    default_action             = var.public_network_access_enabled ? "Allow" : "Deny"
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

  tags = var.tags
}

resource "azurerm_role_assignment" "admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_private_endpoint" "keyvault" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.name}-pep"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = azurerm_key_vault.main.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
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

resource "random_password" "generated" {
  for_each = var.generate_secrets
  length   = each.value.length
  special  = each.value.special
}

resource "azurerm_key_vault_secret" "generated" {
  for_each     = var.generate_secrets
  name         = each.key
  value        = random_password.generated[each.key].result
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.admin]
}

locals {
  # Extract keys from sensitive map for use in for_each
  external_secret_keys = nonsensitive(toset(keys(var.external_secrets)))
}

resource "azurerm_key_vault_secret" "external" {
  for_each     = local.external_secret_keys
  name         = each.key
  value        = var.external_secrets[each.key]
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.admin]
  lifecycle {
    ignore_changes = [value]
  }
}
