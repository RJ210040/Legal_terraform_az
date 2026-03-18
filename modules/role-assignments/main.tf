# -----------------------------------------------------------------------------
# Role Assignments Module
# -----------------------------------------------------------------------------

resource "azurerm_role_assignment" "assignments" {
  # Use static 'name' field as key since principal_id is only known after apply
  for_each                         = { for a in var.role_assignments : a.name => a }
  scope                            = each.value.scope
  role_definition_name             = each.value.role_definition_name
  principal_id                     = each.value.principal_id
  principal_type                   = each.value.principal_type
  skip_service_principal_aad_check = each.value.skip_aad_check
}
