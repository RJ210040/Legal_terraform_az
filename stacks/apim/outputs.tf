output "apim_id"               { value = try(module.apim[0].id, null) }
output "apim_name"             { value = try(module.apim[0].name, null) }
output "gateway_url"           { value = try(module.apim[0].gateway_url, null) }
output "portal_url"            { value = try(module.apim[0].portal_url, null) }
output "identity_principal_id" { value = try(module.apim[0].identity_principal_id, null) }
