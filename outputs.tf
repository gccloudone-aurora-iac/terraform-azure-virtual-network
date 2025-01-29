#######################
### Virtual Network ###
#######################

output "id" {
  description = "The id of the VNet"
  value       = azurerm_virtual_network.this.id
}

output "name" {
  description = "The name of the VNet"
  value       = azurerm_virtual_network.this.name
}

output "resource_group_name" {
  description = "The name of the resource group used by the Virtual Network."
  value       = azurerm_virtual_network.this.resource_group_name
}

output "address_space" {
  description = "The address space of the VNet"
  value       = azurerm_virtual_network.this.address_space
}

output "location" {
  description = "The location of the VNet"
  value       = azurerm_virtual_network.this.location
}

output "vnet_peering_origin_to_remote_ids" {
  description = "The IDs of the Virtual Network Peering."
  value       = { for k, value in azurerm_virtual_network_peering.origin_to_remote : k => value.id }
}

###############
### Subnets ###
###############

output "vnet_subnets" {
  description = "The ids of subnets created inside the VNet"
  value       = azurerm_subnet.this
}

output "vnet_subnets_name_id" {
  description = "Can be queried subnet-id by subnet name by using lookup(module.vnet.vnet_subnets_name_id, subnet1)"
  value       = local.azurerm_subnets
}
