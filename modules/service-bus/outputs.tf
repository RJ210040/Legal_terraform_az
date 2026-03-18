output "namespace_id" { value = azurerm_servicebus_namespace.main.id }
output "namespace_name" { value = azurerm_servicebus_namespace.main.name }
output "primary_connection_string" {
  value     = azurerm_servicebus_namespace.main.default_primary_connection_string
  sensitive = true
}
output "primary_key" {
  value     = azurerm_servicebus_namespace.main.default_primary_key
  sensitive = true
}
output "queue_ids" {
  value = { for k, q in azurerm_servicebus_queue.queues : k => q.id }
}
