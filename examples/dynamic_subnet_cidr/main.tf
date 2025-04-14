locals {
  # The Azure subnet details for the subnets created within the Azure Virtual Network
  subnets = [for subnetName, subnetRange in module.subnet_addrs_example.network_cidr_blocks :
    {
      name        = subnetName
      subnetRange = subnetRange
      nsg_id      = azurerm_network_security_group.example.id
    }
  ]
}

#####################
### Prerequisites ###
#####################

provider "azurerm" {
  features {}
}

# The provider that configures resources in the subscription where the BGP Route Reflector is located. This may differ from the cluster subscription and therefore needs to be specified separately.
# to create the virtual network created within this module.
provider "azurerm" {
  features {}
  alias = "bgp_route_reflector_provider"
}

# Manages an Azure Resource Group.
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group
#
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "Canada Central"
}

# Manages an Azure Network Security Group.
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group
#
resource "azurerm_network_security_group" "example" {
  name                = "examplensg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

#  Terraform module for calculating subnet addresses under a particular CIDR prefix.
#  It ensures the virtual network IP space is consumed from the bottom to the top of the IP space and
#  no IP space unused inbetween subnets.
#
# https://registry.terraform.io/modules/hashicorp/subnets/cidr/latest
#
module "subnet_addrs_example" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = "169.24.0.0/23"
  networks = [
    {
      name     = "loadbalancer"
      new_bits = 4
    },
    {
      name     = "route_server"
      new_bits = 4
    },
    {
      name     = "system"
      new_bits = 3
    },
    {
      name     = "general"
      new_bits = 3
    },
    {
      name     = "gateway"
      new_bits = 3
    }
  ]
}

##############################
### Virtual Network Module ###
##############################

# Manages an Azure Virtual Network and the subnets within it.
#
# https://github.com/gccloudone-aurora-iac/terraform-azurerm-virtual-network
#
module "virtual_network_example" {
  source = "../../"

  naming_convention = "gc"
  user_defined      = "example"

  azure_resource_attributes = {
    department_code = "Gc"
    owner           = "ABC"
    project         = "aur"
    environment     = "dev"
    location        = azurerm_resource_group.example.location
    instance        = 0
  }

  resource_group_name = azurerm_resource_group.example.name
  address_space       = [module.subnet_addrs_example.base_cidr_block]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  subnets = local.subnets

  tags = {
    "tier" = "k8s"
  }

  providers = {
    azurerm                              = azurerm
    azurerm.bgp_route_reflector_provider = azurerm.bgp_route_reflector_provider
  }
}
