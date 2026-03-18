output "postgresql_id" { value = module.postgres.id }
output "postgresql_fqdn" { value = module.postgres.fqdn }
output "postgresql_admin_login" { value = module.postgres.administrator_login }
output "storage_account_id" { value = module.storage.id }
output "storage_account_name" { value = module.storage.name }
output "storage_primary_blob_endpoint" { value = module.storage.primary_blob_endpoint }
output "storage_container_names" { value = module.storage.container_names }
output "storage_file_share_names" { value = module.storage.file_share_names }
output "storage_primary_access_key" {
  value     = module.storage.primary_access_key
  sensitive = true
}
output "servicebus_namespace_id" { value = module.servicebus.namespace_id }
output "servicebus_namespace_name" { value = module.servicebus.namespace_name }
output "servicebus_primary_connection_string" {
  value     = module.servicebus.primary_connection_string
  sensitive = true
}
