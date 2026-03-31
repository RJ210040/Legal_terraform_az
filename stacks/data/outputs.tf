output "postgresql_id"          { value = try(module.postgres[0].id, null) }
output "postgresql_fqdn"        { value = try(module.postgres[0].fqdn, null) }
output "postgresql_admin_login" { value = try(module.postgres[0].administrator_login, null) }

output "storage_account_id"           { value = try(module.storage[0].id, null) }
output "storage_account_name"         { value = try(module.storage[0].name, null) }
output "storage_primary_blob_endpoint"{ value = try(module.storage[0].primary_blob_endpoint, null) }
output "storage_container_names"      { value = try(module.storage[0].container_names, []) }
output "storage_file_share_names"     { value = try(module.storage[0].file_share_names, []) }
output "storage_primary_access_key" {
  value     = try(module.storage[0].primary_access_key, null)
  sensitive = true
}

output "servicebus_namespace_id"   { value = try(module.servicebus[0].namespace_id, null) }
output "servicebus_namespace_name" { value = try(module.servicebus[0].namespace_name, null) }
output "servicebus_primary_connection_string" {
  value     = try(module.servicebus[0].primary_connection_string, null)
  sensitive = true
}
