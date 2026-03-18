output "id" { value = azurerm_storage_account.main.id }
output "name" { value = azurerm_storage_account.main.name }
output "primary_blob_endpoint" { value = azurerm_storage_account.main.primary_blob_endpoint }
output "primary_file_endpoint" { value = azurerm_storage_account.main.primary_file_endpoint }
output "primary_access_key" {
  value     = azurerm_storage_account.main.primary_access_key
  sensitive = true
}
output "primary_connection_string" {
  value     = azurerm_storage_account.main.primary_connection_string
  sensitive = true
}
output "container_names" { value = [for c in azurerm_storage_container.containers : c.name] }
output "file_share_names" { value = [for s in azurerm_storage_share.shares : s.name] }
