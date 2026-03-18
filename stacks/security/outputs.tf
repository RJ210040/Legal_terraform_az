output "keyvault_id" { value = module.keyvault.id }
output "keyvault_name" { value = module.keyvault.name }
output "keyvault_uri" { value = module.keyvault.vault_uri }
output "workload_identity_id" { value = azurerm_user_assigned_identity.workload.id }
output "workload_identity_client_id" { value = azurerm_user_assigned_identity.workload.client_id }
output "workload_identity_principal_id" { value = azurerm_user_assigned_identity.workload.principal_id }
output "postgresql_password_secret_id" { value = module.keyvault.generated_secret_uris["postgresql-admin-password"] }
