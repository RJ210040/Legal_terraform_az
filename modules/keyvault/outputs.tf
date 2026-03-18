output "id" { value = azurerm_key_vault.main.id }
output "name" { value = azurerm_key_vault.main.name }
output "vault_uri" { value = azurerm_key_vault.main.vault_uri }
output "tenant_id" { value = azurerm_key_vault.main.tenant_id }
output "generated_secret_ids" {
  value = { for key, secret in azurerm_key_vault_secret.generated : key => secret.id }
}
output "generated_secret_uris" {
  value = { for key, secret in azurerm_key_vault_secret.generated : key => secret.versionless_id }
}
