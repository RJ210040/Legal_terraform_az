# Dev Environment - Variables (~20 users, cost-optimized)

org_short   = "tv"
project     = "agentic"
environment = "dev"
region      = "eastus2"

# State backend
state_resource_group_name  = "tv-agentic-dev-tfstate-rg"
state_storage_account_name = "tvagenticdevtfstate"
state_container_name       = "tfstate"

# Network
address_space = ["10.0.0.0/16"]
subnet_cidrs = {
  aca  = "10.0.1.0/24"
  aks  = "10.0.2.0/24"
  data = "10.0.3.0/24"
  pep  = "10.0.4.0/24"
  apim = "10.0.5.0/24"
  aci  = "10.0.6.0/24"
}

# Security (relaxed for dev — public access enabled for local development)
enable_private_endpoints = false

# Developer Access - Entra ID object IDs
# Get object ID: az ad user show --id "user@tresvista.net" --query id -o tsv
developer_object_ids = {
  "siddharth.deshpande" = "12964e7b-4e41-48a5-bb83-550c4e842683"
}

# Registry
acr_sku = "Basic"

# Data
postgresql_sku           = "B_Standard_B1ms"
postgresql_storage_mb    = 32768
postgresql_ha_enabled    = false
storage_replication_type = "LRS"

# PostgreSQL firewall (public access since private endpoints are disabled)
postgresql_firewall_rules = [
  {
    name     = "AllowAzureServices"
    start_ip = "0.0.0.0"
    end_ip   = "0.0.0.0"
  },
  {
    name     = "AllowAllForDev"
    start_ip = "0.0.0.0"
    end_ip   = "255.255.255.255"
  }
]

# Monitor
retention_in_days = 30
daily_quota_gb    = 5

# Storage
storage_containers       = ["evidence", "audit-packs"]
enable_versioning        = true
blob_soft_delete_days    = 30

# Service Bus
servicebus_queues = ["evidence-validation", "evidence-notification"]

# Container Apps (scale to zero when idle)
container_apps = [
  {
    name              = "fastapi-backend"
    cpu               = 0.5
    memory            = "1Gi"
    min_replicas      = 0
    max_replicas      = 2
    target_port       = 8000
    health_check_path = "/health"
  },
  {
    name         = "react-frontend"
    cpu          = 0.5
    memory       = "1Gi"
    min_replicas = 0
    max_replicas = 2
    target_port  = 3000
  }
]
