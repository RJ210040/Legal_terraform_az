# -----------------------------------------------------------------------------
# Service Bus Module
# -----------------------------------------------------------------------------

resource "azurerm_servicebus_namespace" "main" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku                           = var.sku
  local_auth_enabled            = var.local_auth_enabled
  public_network_access_enabled = var.public_network_access_enabled

  tags = var.tags
}

resource "azurerm_servicebus_queue" "queues" {
  for_each     = toset(var.queues)
  name         = each.value
  namespace_id = azurerm_servicebus_namespace.main.id

  max_delivery_count                    = var.max_delivery_count
  lock_duration                         = var.lock_duration
  dead_lettering_on_message_expiration  = true
  default_message_ttl                   = var.default_message_ttl
  max_size_in_megabytes                 = var.max_size_in_megabytes
}

resource "azurerm_private_endpoint" "servicebus" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.name}-pep"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = azurerm_servicebus_namespace.main.id
    is_manual_connection           = false
    subresource_names              = ["namespace"]
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
