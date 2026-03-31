# =============================================================================
# PROJECT CONTROL SHEET — Dev Environment
# =============================================================================
# This is the single file you edit for each new project.
# Change the two values under PROJECT IDENTITY, then run the 5-step process.
# All resource names, state backends, and configurations derive from these.
# =============================================================================

# -----------------------------------------------------------------------------
# PROJECT IDENTITY — Change these two values for every new project
# -----------------------------------------------------------------------------
org_short   = "tv"       # Your organisation abbreviation — always "tv"
project     = "legal"    # Project name: lowercase, no spaces, no hyphens
environment = "dev"      # Do not change
region      = "eastus2"  # Change only if data residency requires a different region

# -----------------------------------------------------------------------------
# FEATURE FLAGS — Set true to deploy, false to skip
# Stacks with false will still run but create zero resources (~5s, no cost)
# -----------------------------------------------------------------------------
enable_postgres    = true   # PostgreSQL structured database
enable_storage     = true   # Blob storage + Azure File shares (auto-enabled when enable_qdrant or enable_neo4j = true)
enable_service_bus = true  # Async message queues (disable if no background processing)
enable_qdrant      = true   # Vector database — container app + Azure Files share provisioned automatically
enable_neo4j       = false  # Graph database  — container app + Azure Files share provisioned automatically
enable_apim        = true   # AI API gateway — required if using any AI model

# -----------------------------------------------------------------------------
# ACCESS CONTROL
# enable_private_endpoints = false → resources have public endpoints (dev default)
#   → you can connect to Postgres, Storage, Key Vault from your local machine
# enable_private_endpoints = true  → resources are VNet-only (no local machine access)
#   → only container apps inside the VNet can reach databases
#
# allowed_source_ips: restricts who can reach your Container Apps over HTTPS.
#   Leave empty [] to allow all traffic (typical for dev/internal tools).
#   Add your office/team IP CIDRs to restrict access to the app itself.
#   Example: ["203.0.113.0/24", "198.51.100.42/32"]
# -----------------------------------------------------------------------------
enable_private_endpoints = false

allowed_source_ips = []
# allowed_source_ips = ["YOUR_OFFICE_IP/32"]

# Developer Entra ID object IDs — grants Key Vault Secrets User access so
# developers can read secrets locally with their own Azure login.
# Get yours: az ad user show --id "you@yourcompany.com" --query id -o tsv
developer_object_ids = {
  "siddharth.deshpande" = "12964e7b-4e41-48a5-bb83-550c4e842683"
}

# PostgreSQL firewall — open to all in dev since private endpoints are disabled.
# When enable_private_endpoints = true, this list is ignored (VNet integration takes over).
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

# -----------------------------------------------------------------------------
# NETWORK — typically unchanged across projects
# -----------------------------------------------------------------------------
address_space = ["10.0.0.0/16"]
subnet_cidrs = {
  aca  = "10.0.1.0/24"
  aks  = "10.0.2.0/24"
  data = "10.0.3.0/24"
  pep  = "10.0.4.0/24"
  apim = "10.0.5.0/24"
  aci  = "10.0.6.0/24"
}

# -----------------------------------------------------------------------------
# DATABASES
# -----------------------------------------------------------------------------
postgresql_sku        = "B_Standard_B1ms"  # Small for dev — scale up if needed
postgresql_storage_mb = 32768
postgresql_ha_enabled = false
backup_retention_days = 7
databases             = ["app"]            # Rename to match your project's DB name

# -----------------------------------------------------------------------------
# STORAGE
# -----------------------------------------------------------------------------
acr_sku                  = "Basic"
storage_replication_type = "LRS"
storage_containers  = ["uploads", "exports"]   # Rename to match your use case
storage_file_shares = []                       # Only add custom file shares here; qdrant-data and neo4j-data are managed automatically by the feature flags
enable_versioning        = true
blob_soft_delete_days    = 30

# -----------------------------------------------------------------------------
# MESSAGING (only used when enable_service_bus = true)
# -----------------------------------------------------------------------------
servicebus_sku    = "Standard"
servicebus_queues = ["task-queue", "notification-queue"]  # Rename to your queue names

# -----------------------------------------------------------------------------
# MONITORING
# -----------------------------------------------------------------------------
retention_in_days = 30
daily_quota_gb    = 5

# -----------------------------------------------------------------------------
# CONTAINER APPS — your application containers
# All containers auto-connect to ACR, Key Vault, and Storage via Managed Identity.
# Qdrant and Neo4j are NOT defined here — they are controlled by the feature flags above.
# -----------------------------------------------------------------------------
container_apps = [
  {
    name              = "fastapi-backend"
    cpu               = 0.5
    memory            = "1Gi"
    min_replicas      = 0      # Scales to zero when idle (saves cost in dev)
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
  },
  # ── Qdrant and Neo4j are NOT defined here ────────────────────────────────
  # Set enable_qdrant = true or enable_neo4j = true in the Feature Flags section above.
  # The infrastructure deploys them automatically — no changes needed in this file.
]

# -----------------------------------------------------------------------------
# AI GATEWAY (APIM) — only used when enable_apim = true
# APIM acts as a single endpoint for all AI providers.
# Your apps call one URL; APIM routes to the right provider and handles keys.
# -----------------------------------------------------------------------------
publisher_name  = "TV Engineering"
publisher_email = "infra@tresvista.com"   # Update to your team's email
sku_name        = "Consumption_0"         # Consumption = per-call pricing, no fixed cost in dev

# AI provider backends — add/remove providers your project needs.
# Update azure-openai backend_url with your actual Azure OpenAI resource name after deploying it.
apis = [
  {
    name         = "azure-openai"
    display_name = "Azure OpenAI"
    path         = "ai/azure-openai"
    backend_url  = "https://placeholder.openai.azure.com/openai"  # Update after Azure OpenAI is deployed
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
