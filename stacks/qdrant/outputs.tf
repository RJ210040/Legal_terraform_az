output "qdrant_endpoint" {
  description = "Qdrant HTTP endpoint"
  value = var.environment == "dev" ? (
    local.qdrant_aca_fqdn != null ? "https://${local.qdrant_aca_fqdn}" : null
  ) : try(module.qdrant_aks[0].http_endpoint, null)
}

output "qdrant_internal_endpoint" {
  description = "Qdrant internal endpoint for apps in same environment"
  value = var.environment == "dev" ? (
    local.qdrant_aca_fqdn != null ? "http://${local.qdrant_aca_fqdn}:6333" : null
  ) : try(module.qdrant_aks[0].http_endpoint, null)
}

output "qdrant_grpc_endpoint" {
  description = "Qdrant gRPC endpoint (prod only - Container Apps doesn't support gRPC well)"
  value = var.environment == "dev" ? null : try(module.qdrant_aks[0].grpc_endpoint, null)
}

output "deployment_type" {
  description = "Qdrant deployment type"
  value = var.environment == "dev" ? "container-apps" : "aks"
}
