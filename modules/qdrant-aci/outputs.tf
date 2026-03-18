output "id" { value = azurerm_container_group.qdrant.id }
output "name" { value = azurerm_container_group.qdrant.name }
output "ip_address" { value = azurerm_container_group.qdrant.ip_address }
output "fqdn" { value = azurerm_container_group.qdrant.fqdn }
output "http_port" { value = 6333 }
output "grpc_port" { value = 6334 }
output "http_endpoint" { value = "http://${azurerm_container_group.qdrant.ip_address}:6333" }
output "grpc_endpoint" { value = "${azurerm_container_group.qdrant.ip_address}:6334" }
