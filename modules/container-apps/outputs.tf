output "environment_id" { value = azurerm_container_app_environment.main.id }
output "environment_name" { value = azurerm_container_app_environment.main.name }
output "default_domain" { value = azurerm_container_app_environment.main.default_domain }
output "static_ip" { value = azurerm_container_app_environment.main.static_ip_address }
output "app_ids" { value = { for name, app in azurerm_container_app.apps : name => app.id } }
output "app_fqdns" { value = { for name, app in azurerm_container_app.apps : name => try(app.ingress[0].fqdn, null) } }
output "app_urls" { value = { for name, app in azurerm_container_app.apps : name => try("https://${app.ingress[0].fqdn}", null) } }
output "app_identities" { value = { for name, app in azurerm_container_app.apps : name => app.identity[0].principal_id } }
