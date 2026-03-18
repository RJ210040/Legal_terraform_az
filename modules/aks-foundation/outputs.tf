output "id" { value = azurerm_kubernetes_cluster.main.id }
output "name" { value = azurerm_kubernetes_cluster.main.name }
output "fqdn" { value = azurerm_kubernetes_cluster.main.fqdn }
output "kube_config" {
  value     = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive = true
}
output "kube_config_host" { value = azurerm_kubernetes_cluster.main.kube_config[0].host }
output "identity_principal_id" { value = azurerm_kubernetes_cluster.main.identity[0].principal_id }
output "kubelet_identity_object_id" { value = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id }
output "oidc_issuer_url" { value = var.enable_oidc_issuer ? azurerm_kubernetes_cluster.main.oidc_issuer_url : null }
output "node_resource_group" { value = azurerm_kubernetes_cluster.main.node_resource_group }
