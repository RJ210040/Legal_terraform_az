output "workspace_id" { value = module.monitor.workspace_id }
output "workspace_name" { value = module.monitor.workspace_name }
output "workspace_customer_id" { value = module.monitor.workspace_customer_id }
output "app_insights_id" { value = module.monitor.app_insights_id }
output "instrumentation_key" {
  value     = module.monitor.instrumentation_key
  sensitive = true
}
output "connection_string" {
  value     = module.monitor.connection_string
  sensitive = true
}
