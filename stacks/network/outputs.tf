output "vnet_id" { value = module.network.vnet_id }
output "vnet_name" { value = module.network.vnet_name }
output "subnet_ids" { value = module.network.subnet_ids }
output "nsg_ids" { value = module.network.nsg_ids }
output "private_dns_zone_ids" { value = module.network.private_dns_zone_ids }
output "private_dns_zone_names" { value = module.network.private_dns_zone_names }
