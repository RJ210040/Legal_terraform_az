# -----------------------------------------------------------------------------
# Naming Module - Outputs
# -----------------------------------------------------------------------------

output "names" {
  description = "Map of all generated resource names"
  value       = local.names
}

output "resource_group" {
  value = local.names.resource_group
}

output "virtual_network" {
  value = local.names.virtual_network
}

output "subnets" {
  value = {
    aca  = local.names.subnet_aca
    aks  = local.names.subnet_aks
    data = local.names.subnet_data
    pep  = local.names.subnet_pep
    apim = local.names.subnet_apim
    aci  = local.names.subnet_aci
  }
}

output "container_app_environment" {
  value = local.names.container_app_environment
}

output "kubernetes_cluster" {
  value = local.names.kubernetes_cluster
}

output "postgresql_server" {
  value = local.names.postgresql_server
}

output "storage_account" {
  value = local.names.storage_account
}

output "key_vault" {
  value = local.names.key_vault
}

output "container_registry" {
  value = local.names.container_registry
}

output "api_management" {
  value = local.names.api_management
}

output "service_bus_namespace" {
  value = local.names.service_bus_namespace
}

output "log_analytics_workspace" {
  value = local.names.log_analytics_workspace
}

output "application_insights" {
  value = local.names.application_insights
}

output "managed_identity" {
  value = local.names.managed_identity
}

output "private_dns_zones" {
  value = {
    acr        = local.names.private_dns_acr
    postgres   = local.names.private_dns_postgres
    keyvault   = local.names.private_dns_keyvault
    blob       = local.names.private_dns_blob
    openai     = local.names.private_dns_openai
    servicebus = local.names.private_dns_servicebus
  }
}

output "name_prefix" {
  value = local.name_prefix
}

output "common_tags" {
  value = local.common_tags
}

output "region_short" {
  value = local.region_short
}
