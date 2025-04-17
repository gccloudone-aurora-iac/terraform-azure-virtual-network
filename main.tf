#######################
### Virtual Network ###
#######################

# Manages an Azure Virtual Network.
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network
#
resource "azurerm_virtual_network" "this" {
  name                = module.azure_resource_names.virtual_network_name
  location            = var.azure_resource_attributes.location
  resource_group_name = var.resource_group_name

  address_space = var.address_space
  dns_servers   = var.dns_servers
  tags          = local.tags

  dynamic "ddos_protection_plan" {
    for_each = var.ddos_protection_plan_id != null ? ["ddos_protection_plan"] : []

    content {
      enable = true
      id     = var.ddos_protection_plan_id
    }
  }
}

# Manages a virtual network peering which allows access to resources in the peered virtual network.
# Create a Virtual Network peering on the new VNet.
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering
#
resource "azurerm_virtual_network_peering" "origin_to_remote" {
  for_each = { for index, value in local.vnet_peers : value.virtual_network_name => value }

  name                      = each.value.virtual_network_name
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.this.name
  remote_virtual_network_id = each.value.virtual_network_id

  // These dependencies aim to fix the issue recorded in https://github.com/hashicorp/terraform-provider-azurerm/issues/2605
  depends_on = [
    azurerm_subnet.this,
    azurerm_subnet_network_security_group_association.this,
    azurerm_subnet_route_table_association.this
  ]
}

###############
### Subnets ###
###############

# Manages an Azure Subnet.
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet
#
resource "azurerm_subnet" "this" {
  for_each = { for index, subnet in var.subnets : subnet.name => subnet }

  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name

  address_prefixes = each.value.address_prefixes

  private_endpoint_network_policies             = each.value.private_endpoint_network_policies_enabled
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled
  service_endpoints                             = each.value.service_endpoints
  service_endpoint_policy_ids                   = try([azurerm_subnet_service_endpoint_storage_policy.this[each.key].id], null)

  dynamic "delegation" {
    for_each = each.value.service_delegation_name != null ? ["service_delegation"] : []

    content {
      name = replace(each.value.service_delegation_name, "/", ".")

      service_delegation {
        name = each.value.service_delegation_name
      }
    }
  }

  lifecycle {
    ignore_changes = [
      delegation[0].service_delegation[0].actions
    ]
  }
}

# Associates Azure Network Security Group(s) to subnets.
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association
#
resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = { for index, value in var.subnet_nsgs : value.subnet_name => value }

  network_security_group_id = each.value.nsg_id
  subnet_id                 = azurerm_subnet.this[each.value.subnet_name].id
}

# Associates Azure Route Table(s) to subnets.
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association
#
resource "azurerm_subnet_route_table_association" "this" {
  for_each = { for index, value in var.subnet_route_tables : value.subnet_name => value }

  route_table_id = each.value.route_table_id
  subnet_id      = azurerm_subnet.this[each.value.subnet_name].id
}

# An Azure Service Endpoint Storage Policy that can be applied to a subnet.
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_service_endpoint_storage_policy
#
resource "azurerm_subnet_service_endpoint_storage_policy" "this" {
  for_each = { for index, subnet in var.subnets : subnet.name => subnet if subnet.service_endpoint_policy_definitions != null }

  name                = "${module.azure_resource_names.service_endpoint_policy_name}-${each.key}"
  resource_group_name = var.resource_group_name
  location            = var.azure_resource_attributes.location

  dynamic "definition" {
    for_each = { for index, policy in each.value.service_endpoint_policy_definitions : index => policy }

    content {
      name              = definition.value.name != null ? definition.value.name : replace(lower(definition.value.service), ".", "-")
      description       = definition.value.description != null ? definition.value.description : "Associated to the ${each.key} subnet within the ${azurerm_virtual_network.this.name} virtual network"
      service           = definition.value.service
      service_resources = definition.value.scopes
    }
  }

  tags = local.tags
}
