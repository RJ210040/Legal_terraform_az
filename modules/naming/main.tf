# -----------------------------------------------------------------------------
# Naming Module
# Generates CAF-compliant, deterministic resource names for Azure resources
# Format: {org}-{project}-{env}-{region_short}-{resource_type}-{sequence}
# -----------------------------------------------------------------------------

locals {
  # Region short codes mapping
  region_short_codes = {
    "eastus"         = "eus"
    "eastus2"        = "eus2"
    "westus"         = "wus"
    "westus2"        = "wus2"
    "westus3"        = "wus3"
    "centralus"      = "cus"
    "northeurope"    = "neu"
    "westeurope"     = "weu"
    "uksouth"        = "uks"
    "ukwest"         = "ukw"
    "southeastasia"  = "sea"
    "eastasia"       = "eas"
    "australiaeast"  = "aue"
    "japaneast"      = "jpe"
    "canadacentral"  = "cac"
    "brazilsouth"    = "brs"
    "southcentralus" = "scus"
    "northcentralus" = "ncus"
    "westcentralus"  = "wcus"
  }

  region_short = lookup(local.region_short_codes, var.region, substr(var.region, 0, 4))

  # Base naming prefix: org-project-env-region
  name_prefix = "${var.org_short}-${var.project}-${var.environment}-${local.region_short}"

  # Sequence suffix
  seq = format("%03d", var.sequence)

  # Resource names with CAF abbreviations
  names = {
    resource_group          = "${local.name_prefix}-rg"
    virtual_network         = "${local.name_prefix}-vnet-${local.seq}"
    subnet_aca              = "${local.name_prefix}-snet-aca-${local.seq}"
    subnet_aks              = "${local.name_prefix}-snet-aks-${local.seq}"
    subnet_data             = "${local.name_prefix}-snet-data-${local.seq}"
    subnet_pep              = "${local.name_prefix}-snet-pep-${local.seq}"
    subnet_apim             = "${local.name_prefix}-snet-apim-${local.seq}"
    subnet_aci              = "${local.name_prefix}-snet-aci-${local.seq}"
    network_security_group  = "${local.name_prefix}-nsg"
    private_endpoint_prefix = "${local.name_prefix}-pep"
    container_app_environment = "${local.name_prefix}-cae-${local.seq}"
    container_app_prefix      = "${local.name_prefix}-ca"
    kubernetes_cluster        = "${local.name_prefix}-aks-${local.seq}"
    container_instance        = "${local.name_prefix}-aci-${local.seq}"
    postgresql_server = "${local.name_prefix}-psql-${local.seq}"
    storage_account   = lower(replace("${var.org_short}${var.project}${var.environment}st${local.seq}", "-", ""))
    key_vault         = "${local.name_prefix}-kv"  # Max 24 chars, no sequence needed
    managed_identity  = "${local.name_prefix}-id-${local.seq}"
    container_registry = lower(replace("${var.org_short}${var.project}${var.environment}acr${local.seq}", "-", ""))
    api_management          = "${local.name_prefix}-apim-${local.seq}"
    service_bus_namespace   = "${local.name_prefix}-sbns-${local.seq}"
    log_analytics_workspace = "${local.name_prefix}-law-${local.seq}"
    application_insights    = "${local.name_prefix}-ai-${local.seq}"
    private_dns_acr        = "privatelink.azurecr.io"
    private_dns_postgres   = "privatelink.postgres.database.azure.com"
    private_dns_keyvault   = "privatelink.vaultcore.azure.net"
    private_dns_blob       = "privatelink.blob.core.windows.net"
    private_dns_openai     = "privatelink.openai.azure.com"
    private_dns_servicebus = "privatelink.servicebus.windows.net"
  }

  common_tags = merge(
    {
      environment  = var.environment
      project      = var.project
      organization = var.org_short
      managed_by   = "terraform"
    },
    var.extra_tags
  )
}
