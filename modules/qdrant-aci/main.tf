# -----------------------------------------------------------------------------
# Qdrant ACI Module (dev)
# -----------------------------------------------------------------------------

resource "azurerm_container_group" "qdrant" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  ip_address_type     = var.subnet_id != null ? "Private" : "Public"
  subnet_ids          = var.subnet_id != null ? [var.subnet_id] : null
  restart_policy      = "Always"

  container {
    name   = "qdrant"
    image  = var.qdrant_image
    cpu    = var.cpu
    memory = var.memory_gb

    ports {
      port     = 6333
      protocol = "TCP"
    }
    ports {
      port     = 6334
      protocol = "TCP"
    }

    environment_variables = merge({ "QDRANT__SERVICE__GRPC_PORT" = "6334" }, var.environment_variables)

    dynamic "volume" {
      for_each = var.storage_account_name != null ? [1] : []
      content {
        name                 = "qdrant-data"
        mount_path           = "/qdrant/storage"
        share_name           = var.file_share_name
        storage_account_name = var.storage_account_name
        storage_account_key  = var.storage_account_key
      }
    }

    liveness_probe {
      http_get {
        path   = "/healthz"
        port   = 6333
        scheme = "http"
      }
      initial_delay_seconds = 10
      period_seconds        = 30
    }

    readiness_probe {
      http_get {
        path   = "/readyz"
        port   = 6333
        scheme = "http"
      }
      initial_delay_seconds = 5
      period_seconds        = 10
    }
  }

  tags = var.tags
}
