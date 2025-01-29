locals {
  azurerm_subnets = {
    for index, subnet in azurerm_subnet.this :
    subnet.name => subnet.id
  }
  vnet_peers = [
    for vnet_resource_id in var.vnet_peers : {
      virtual_network_id   = vnet_resource_id
      virtual_network_name = element(split("/", vnet_resource_id), length(split("/", vnet_resource_id)) - 1) // The last index by splitting the resource ID by /
      resource_group_name  = element(split("/", vnet_resource_id), 4)
    }
  ]

  tags = merge(
    var.tags,
    {
      ModuleName    = "terraform-azure-virtual-network",
      ModuleVersion = "v1.0.0",
    }
  )
}
