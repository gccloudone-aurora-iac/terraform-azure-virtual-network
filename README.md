# Terraform Azurerm Virtual Network

This Terraform module deploys a [Virtual Network](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview) in Azure with a set of subnets passed in as input parameters. Moreover, this module can be used to associate route tables and NSGs to the subnets created.

> The configuration within this module was heavily inspired from https://github.com/Azure/terraform-azurerm-vnet.

## Usage

Examples for this module along with various configurations can be found in the [examples/](examples/) folder.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.15, < 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.73.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_azure_resource_names"></a> [azure\_resource\_names](#module\_azure\_resource\_names) | git::https://github.com/gccloudone-aurora-iac/terraform-aurora-azure-resource-names.git | v2.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_address_space"></a> [address\_space](#input\_address\_space) | The address space that is used by the virtual network. | `list(string)` | n/a | yes |
| <a name="input_azure_resource_attributes"></a> [azure\_resource\_attributes](#input\_azure\_resource\_attributes) | Attributes used to describe Azure resources | <pre>object({<br>    project     = string<br>    environment = string<br>    location    = optional(string, "Canada Central")<br>    instance    = number<br>  })</pre> | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group to be imported. | `string` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | The subnets created within the VNet | <pre>list(object({<br>    name             = string<br>    address_prefixes = list(string)<br><br>    nsg_id         = optional(string)<br>    route_table_id = optional(string)<br><br>    service_endpoints = optional(list(string), [])<br>    service_endpoint_policy = optional(object({<br>      storage_account_ids = list(string)<br>      aliases             = optional(list(string))<br>    }))<br><br>    private_endpoint_network_policies_enabled     = optional(bool, true)<br>    private_link_service_network_policies_enabled = optional(bool, true)<br><br>    service_delegations = optional(list(object({<br>      name    = string<br>      actions = optional(list(string))<br>    })))<br>  }))</pre> | n/a | yes |
| <a name="input_ddos_protection_plan"></a> [ddos\_protection\_plan](#input\_ddos\_protection\_plan) | The set of DDoS protection plan configuration | <pre>object({<br>    enable = bool<br>    id     = string<br>  })</pre> | `null` | no |
| <a name="input_dns_servers"></a> [dns\_servers](#input\_dns\_servers) | The DNS servers to be used with VNet. If no values specified, this defaults to Azure DNS. | `list(string)` | `[]` | no |
| <a name="input_subnet_nsgs"></a> [subnet\_nsgs](#input\_subnet\_nsgs) | n/a | <pre>list(object({<br>    subnet_name = string<br>    nsg_id      = string<br>  }))</pre> | `[]` | no |
| <a name="input_subnet_route_tables"></a> [subnet\_route\_tables](#input\_subnet\_route\_tables) | n/a | <pre>list(object({<br>    subnet_name    = string<br>    route_table_id = string<br>  }))</pre> | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | The tags to associate with your network and subnets. | `map(string)` | `{}` | no |
| <a name="input_vnet_peers"></a> [vnet\_peers](#input\_vnet\_peers) | A list of remote virtual network resource IDs to use as virtual network peerings. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_address_space"></a> [address\_space](#output\_address\_space) | The address space of the VNet |
| <a name="output_id"></a> [id](#output\_id) | The id of the VNet |
| <a name="output_location"></a> [location](#output\_location) | The location of the VNet |
| <a name="output_name"></a> [name](#output\_name) | The name of the VNet |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | The name of the resource group used by the Virtual Network. |
| <a name="output_vnet_peering_origin_to_remote_ids"></a> [vnet\_peering\_origin\_to\_remote\_ids](#output\_vnet\_peering\_origin\_to\_remote\_ids) | The IDs of the Virtual Network Peering. |
| <a name="output_vnet_peering_remote_to_origin_ids"></a> [vnet\_peering\_remote\_to\_origin\_ids](#output\_vnet\_peering\_remote\_to\_origin\_ids) | The IDs of the Virtual Network Peering. |
| <a name="output_vnet_subnets"></a> [vnet\_subnets](#output\_vnet\_subnets) | The ids of subnets created inside the VNet |
| <a name="output_vnet_subnets_name_id"></a> [vnet\_subnets\_name\_id](#output\_vnet\_subnets\_name\_id) | Can be queried subnet-id by subnet name by using lookup(module.vnet.vnet\_subnets\_name\_id, subnet1) |
<!-- END_TF_DOCS -->

## History

| Date       | Release | Change                                                                                                   |
| ---------- | ------- | -------------------------------------------------------------------------------------------------------- |
| 2025-01-25 | v1.0.0  | Initial commit                                                                                           |
