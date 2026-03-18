output "id" { value = azurerm_api_management.main.id }
output "name" { value = azurerm_api_management.main.name }
output "gateway_url" { value = azurerm_api_management.main.gateway_url }
output "portal_url" { value = azurerm_api_management.main.portal_url }
output "identity_principal_id" { value = azurerm_api_management.main.identity[0].principal_id }
