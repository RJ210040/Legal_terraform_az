output "cluster_id" { value = module.aks.id }
output "cluster_name" { value = module.aks.name }
output "cluster_fqdn" { value = module.aks.fqdn }
output "kube_config" {
  value     = module.aks.kube_config
  sensitive = true
}
output "kube_config_host" { value = module.aks.kube_config_host }
output "kubelet_identity_object_id" { value = module.aks.kubelet_identity_object_id }
output "oidc_issuer_url" { value = module.aks.oidc_issuer_url }
