output "workspace_id" { value = azurerm_log_analytics_workspace.main.id }
output "workspace_name" { value = azurerm_log_analytics_workspace.main.name }
output "workspace_customer_id" { value = azurerm_log_analytics_workspace.main.workspace_id }
output "primary_shared_key" {
  value     = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive = true
}
output "app_insights_id" { value = azurerm_application_insights.main.id }
output "app_insights_name" { value = azurerm_application_insights.main.name }
output "instrumentation_key" {
  value     = azurerm_application_insights.main.instrumentation_key
  sensitive = true
}
output "connection_string" {
  value     = azurerm_application_insights.main.connection_string
  sensitive = true
}
