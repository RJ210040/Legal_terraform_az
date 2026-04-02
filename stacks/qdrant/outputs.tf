output "qdrant_endpoint" {
  description = "Qdrant HTTP endpoint"
  value = contains(["dev", "mvp"], var.environment) ? (
    local.qdrant_aca_fqdn != null ? "https://${local.qdrant_aca_fqdn}" : null
  ) : try(module.qdrant_aks[0].http_endpoint, null)
}

output "qdrant_internal_endpoint" {
  description = "Qdrant internal endpoint for apps in same environment"
  value = contains(["dev", "mvp"], var.environment) ? (
    local.qdrant_aca_fqdn != null ? "http://${local.qdrant_aca_fqdn}:6333" : null
  ) : try(module.qdrant_aks[0].http_endpoint, null)
}

output "qdrant_grpc_endpoint" {
  description = "Qdrant gRPC endpoint (prod only - Container Apps doesn't support gRPC well)"
  value = contains(["dev", "mvp"], var.environment) ? null : try(module.qdrant_aks[0].grpc_endpoint, null)
}

output "deployment_type" {
  description = "Qdrant deployment type"
  value = contains(["dev", "mvp"], var.environment) ? "container-apps" : "aks"
}
