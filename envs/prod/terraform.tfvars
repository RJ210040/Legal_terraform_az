# =============================================================================
# PROJECT CONTROL SHEET — Prod Environment
# =============================================================================
# Must match the project identity in envs/dev/terraform.tfvars exactly.
# Only the sizing, redundancy, and security settings differ from dev.
# =============================================================================

# -----------------------------------------------------------------------------
# PROJECT IDENTITY — Must match dev exactly
# -----------------------------------------------------------------------------
org_short   = "tv"
project     = "legal"
environment = "prod"
region      = "eastus2"

# -----------------------------------------------------------------------------
# FEATURE FLAGS — Mirror your dev settings unless prod has different requirements
# -----------------------------------------------------------------------------
enable_postgres    = true
enable_storage     = true
enable_service_bus = false
enable_qdrant      = true
enable_neo4j       = false  # Graph database — match dev setting
enable_apim        = true

# -----------------------------------------------------------------------------
# ACCESS CONTROL
# Prod uses private endpoints: databases are VNet-only, not internet-accessible.
# Container Apps still have public HTTPS ingress for your users.
#
# allowed_source_ips: restrict which IPs can reach the Container Apps.
# Set to your users' IP ranges if you want an internal/restricted app.
# Leave empty to allow public access (typical for customer-facing apps).
# -----------------------------------------------------------------------------
enable_private_endpoints = true

allowed_source_ips = []

# Developer access — Entra ID object IDs for Key Vault read access.
developer_object_ids = {
  "siddharth.deshpande" = "12964e7b-4e41-48a5-bb83-550c4e842683"
}

# Firewall rules are ignored in prod when private endpoints are enabled.
postgresql_firewall_rules = []

# -----------------------------------------------------------------------------
# NETWORK
# -----------------------------------------------------------------------------
address_space = ["10.0.0.0/16"]
subnet_cidrs = {
  aca  = "10.0.1.0/24"
  aks  = "10.0.2.0/23"   # /23 for AKS node pool (requires more IPs)
  data = "10.0.4.0/24"
  pep  = "10.0.5.0/24"
  apim = "10.0.6.0/24"
  aci  = "10.0.7.0/24"
}

# -----------------------------------------------------------------------------
# DATABASES — Production sizing with high availability
# -----------------------------------------------------------------------------
postgresql_sku        = "GP_Standard_D4s_v3"
postgresql_storage_mb = 262144
postgresql_ha_enabled = true
backup_retention_days = 35
databases             = ["app"]

# -----------------------------------------------------------------------------
# STORAGE — Zone-redundant for prod resilience
# -----------------------------------------------------------------------------
acr_sku                  = "Premium"
geo_replications = [
  {
    location                = "westus2"
    zone_redundancy_enabled = true
  }
]
storage_replication_type = "ZRS"
storage_containers  = ["uploads", "exports"]
storage_file_shares = []   # qdrant-data and neo4j-data are managed automatically by feature flags
enable_versioning        = true
blob_soft_delete_days    = 90

# -----------------------------------------------------------------------------
# MESSAGING
# -----------------------------------------------------------------------------
servicebus_sku    = "Premium"   # Premium required for VNet integration in prod
servicebus_queues = ["task-queue", "notification-queue"]

# -----------------------------------------------------------------------------
# MONITORING — Longer retention for compliance
# -----------------------------------------------------------------------------
retention_in_days = 90
daily_quota_gb    = -1   # Unlimited

# -----------------------------------------------------------------------------
# CONTAINER APPS — Always-on in prod (min_replicas >= 1)
# Qdrant and Neo4j are NOT listed here — they are managed by the feature flags above.
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# AI GATEWAY (APIM)
# -----------------------------------------------------------------------------
publisher_name  = "TV Engineering"
publisher_email = "infra@tresvista.com"
sku_name        = "Developer_1"   # Developer SKU in prod for VNet integration (~$50/day)
                                   # Upgrade to Standard_1 for SLA-backed production

apis = [
  {
    name         = "azure-openai"
    display_name = "Azure OpenAI"
    path         = "ai/azure-openai"
    backend_url  = "https://placeholder.openai.azure.com/openai"
  },
  {
    name         = "openai-direct"
    display_name = "OpenAI Direct"
    path         = "ai/openai"
    backend_url  = "https://api.openai.com/v1"
  },
  {
    name         = "claude"
    display_name = "Anthropic Claude"
    path         = "ai/claude"
    backend_url  = "https://api.anthropic.com/v1"
  }
]

products = [
  {
    id                    = "ai-services"
    display_name          = "AI Services"
    description           = "Access to all AI model endpoints"
    subscription_required = true
    approval_required     = false
    published             = true
  }
]

api_product_links = [
  { api_name = "azure-openai",  product_id = "ai-services" },
  { api_name = "openai-direct", product_id = "ai-services" },
  { api_name = "claude",        product_id = "ai-services" }
]
