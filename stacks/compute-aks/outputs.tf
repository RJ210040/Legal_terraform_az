output "cluster_id"                 { value = try(module.aks[0].id, null) }
output "cluster_name"               { value = try(module.aks[0].name, null) }
output "cluster_fqdn"               { value = try(module.aks[0].fqdn, null) }
output "kube_config" {
  value     = try(module.aks[0].kube_config, null)
  sensitive = true
}
output "kube_config_host"           { value = try(module.aks[0].kube_config_host, null) }
output "kubelet_identity_object_id" { value = try(module.aks[0].kubelet_identity_object_id, null) }
output "oidc_issuer_url"            { value = try(module.aks[0].oidc_issuer_url, null) }
