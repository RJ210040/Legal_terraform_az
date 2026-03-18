# -----------------------------------------------------------------------------
# Network Module - Outputs
# -----------------------------------------------------------------------------

output "vnet_id" {
  value = azurerm_virtual_network.main.id
}

output "vnet_name" {
  value = azurerm_virtual_network.main.name
}

output "subnet_ids" {
  value = {
    aca  = azurerm_subnet.aca.id
    aks  = var.enable_aks_subnet ? azurerm_subnet.aks[0].id : null
    data = azurerm_subnet.data.id
    pep  = azurerm_subnet.pep.id
    apim = azurerm_subnet.apim.id
    aci  = var.enable_aci_subnet ? azurerm_subnet.aci[0].id : null
  }
}

output "nsg_ids" {
  value = {
    aca  = azurerm_network_security_group.aca.id
    data = azurerm_network_security_group.data.id
    pep  = azurerm_network_security_group.pep.id
  }
}

output "private_dns_zone_ids" {
  value = { for key, zone in azurerm_private_dns_zone.zones : key => zone.id }
}

output "private_dns_zone_names" {
  value = { for key, zone in azurerm_private_dns_zone.zones : key => zone.name }
}
