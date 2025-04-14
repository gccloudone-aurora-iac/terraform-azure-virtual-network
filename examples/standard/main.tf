#####################
### Prerequisites ###
#####################

provider "azurerm" {
  features {}
}

# The resource group that the Virtual Network will be created within.
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group
#
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "Canada Central"
}

# The Network Security Group that will be associated with some of the subnets by the Virtual Network module.
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group
#
resource "azurerm_network_security_group" "example" {
  name                = "testnsg"
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

# The Storage Account that will be used by a Service Endpoint Policy configured within the Virtual Network module.
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account.html
#
resource "azurerm_storage_account" "example" {
  name                     = "standardvnetex"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# The Virtual Network that will be peered to by the Virtual Network created within the Virtual Network module.
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network
#
resource "azurerm_virtual_network" "remote" {
  name                = "example-remote-vnet"
  address_space       = ["172.16.0.0/16"]
  location            = "Canada Central"
  resource_group_name = azurerm_resource_group.example.name
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

  address_space = ["10.0.0.0/16"]
  dns_servers   = ["10.0.0.4", "10.0.0.5"]
  vnet_peers    = [azurerm_virtual_network.remote.id]

  subnets = [
    {
      name                    = "postgresql-databases"
      address_prefixes        = ["10.0.1.0/24"]
      nsg_id                  = azurerm_network_security_group.example.id
      service_delegation_name = "Microsoft.DBforPostgreSQL/flexibleServers"
    },
    {
      name             = "infrastructure"
      address_prefixes = ["10.0.2.0/24"]
      nsg_id           = azurerm_network_security_group.example.id
    },
    {
      name              = "system"
      address_prefixes  = ["10.0.3.0/24"]
      service_endpoints = ["Microsoft.Storage"]
      service_endpoint_policy_definitions = [
        {
          scopes = [azurerm_storage_account.example.id]
        },
        {
          service = "Global"
          scopes  = ["/services/Azure", "/services/Azure/Batch"]
        },
      ]
    }
  ]

  tags = {
    "tier" = "k8s"
  }

  depends_on = [azurerm_virtual_network.remote]
}
