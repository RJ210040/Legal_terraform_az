output "id" { value = azurerm_postgresql_flexible_server.main.id }
output "name" { value = azurerm_postgresql_flexible_server.main.name }
output "fqdn" { value = azurerm_postgresql_flexible_server.main.fqdn }
output "administrator_login" { value = azurerm_postgresql_flexible_server.main.administrator_login }
output "administrator_password" {
  value     = local.admin_password
  sensitive = true
}
output "connection_string" {
  value = "postgresql://${azurerm_postgresql_flexible_server.main.administrator_login}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${var.databases[0]}?sslmode=require"
}
output "connection_string_full" {
  value     = "postgresql://${azurerm_postgresql_flexible_server.main.administrator_login}:${local.admin_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${var.databases[0]}?sslmode=require"
  sensitive = true
}
