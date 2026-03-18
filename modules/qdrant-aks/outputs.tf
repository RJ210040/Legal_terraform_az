output "release_name" { value = helm_release.qdrant.name }
output "namespace" { value = var.create_namespace ? kubernetes_namespace_v1.qdrant[0].metadata[0].name : var.namespace }
output "service_name" { value = var.release_name }
output "service_endpoint" { value = "${var.release_name}.${var.namespace}.svc.cluster.local" }
output "http_port" { value = 6333 }
output "grpc_port" { value = 6334 }
output "http_endpoint" { value = "http://${var.release_name}.${var.namespace}.svc.cluster.local:6333" }
output "grpc_endpoint" { value = "${var.release_name}.${var.namespace}.svc.cluster.local:6334" }
