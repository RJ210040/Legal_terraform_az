# Prod Environment - Variables (~1000 users, high availability)

org_short   = "tv"
project     = "agentic"
environment = "prod"
region      = "eastus2"

# State backend
state_resource_group_name  = "tv-agentic-prod-tfstate-rg"
state_storage_account_name = "tvagenticprodtfstate"
state_container_name       = "tfstate"

# Network
address_space = ["10.0.0.0/16"]
subnet_cidrs = {
  aca  = "10.0.1.0/24"
  aks  = "10.0.2.0/23"
  data = "10.0.4.0/24"
  pep  = "10.0.5.0/24"
  apim = "10.0.6.0/24"
  aci  = "10.0.7.0/24"
}

# Security
enable_private_endpoints = true

# Registry
acr_sku = "Premium"
geo_replications = [
  {
    location                = "westus2"
    zone_redundancy_enabled = true
  }
]

# Data
postgresql_sku           = "GP_Standard_D4s_v3"
postgresql_storage_mb    = 262144
postgresql_ha_enabled    = true
backup_retention_days    = 35
storage_replication_type = "ZRS"
storage_containers       = ["evidence", "audit-packs"]
enable_versioning        = true
blob_soft_delete_days    = 90

# Monitor
retention_in_days = 90
daily_quota_gb    = -1

# Service Bus
servicebus_queues = ["evidence-validation", "evidence-notification"]

# Container Apps (always running)
container_apps = [
  {
    name              = "fastapi-backend"
    cpu               = 1.0
    memory            = "2Gi"
    min_replicas      = 2
    max_replicas      = 10
    target_port       = 8000
    health_check_path = "/health"
  },
  {
    name         = "react-frontend"
    cpu          = 1.0
    memory       = "2Gi"
    min_replicas = 2
    max_replicas = 10
    target_port  = 3000
  }
]
