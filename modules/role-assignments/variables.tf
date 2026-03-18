variable "role_assignments" {
  description = "List of role assignments to create"
  type = list(object({
    name                 = string # Static key for for_each (must be known at plan time)
    scope                = string
    role_definition_name = string
    principal_id         = string
    principal_type       = optional(string, "ServicePrincipal")
    skip_aad_check       = optional(bool, false)
  }))
  default = []
}
