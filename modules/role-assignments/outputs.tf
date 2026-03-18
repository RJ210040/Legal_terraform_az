output "assignment_ids" {
  value = { for key, a in azurerm_role_assignment.assignments : key => a.id }
}
output "assignment_count" { value = length(azurerm_role_assignment.assignments) }
