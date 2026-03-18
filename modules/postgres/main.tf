# -----------------------------------------------------------------------------
# PostgreSQL Flexible Server Module
# -----------------------------------------------------------------------------

resource "random_password" "admin" {
  length  = 32
  special = true
}

locals {
  # Always use generated password if none provided
  # Using coalesce avoids the sensitive value conditional bug in Terraform
  admin_password = coalesce(var.administrator_password, random_password.admin.result)
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  administrator_login    = var.administrator_login
  administrator_password = local.admin_password

  sku_name   = var.sku_name
  version    = var.postgres_version
  storage_mb = var.storage_mb

  delegated_subnet_id = var.delegated_subnet_id
  private_dns_zone_id = var.private_dns_zone_id

  # Public access must be disabled when using VNet integration
  public_network_access_enabled = var.delegated_subnet_id == null ? true : false

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  dynamic "high_availability" {
    for_each = var.ha_enabled ? [1] : []
    content {
      mode                      = "ZoneRedundant"
      standby_availability_zone = var.standby_availability_zone
    }
  }

  zone = var.availability_zone

  tags = var.tags

  lifecycle {
    ignore_changes = [zone]
  }
}

resource "azurerm_postgresql_flexible_server_configuration" "extensions" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = join(",", var.extensions)
}

resource "azurerm_postgresql_flexible_server_database" "databases" {
  for_each  = toset(var.databases)
  name      = each.value
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}
