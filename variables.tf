variable "azure_resource_attributes" {
  description = "Attributes used to describe Azure resources"
  type = object({
    department_code = string
    owner           = string
    project         = string
    environment     = string
    location        = optional(string, "Canada Central")
    instance        = number
  })
  nullable = false
}

variable "user_defined" {
  description = "A user-defined field that describes the Azure resource."
  type        = string
  nullable    = false

  validation {
    condition     = length(var.user_defined) >= 2 && length(var.user_defined) <= 15
    error_message = "The user-defined field must be between 2-15 characters long."
  }
}

variable "naming_convention" {
  type        = string
  default     = "oss"
  description = "Sets which naming convention to use. Accepted values: oss, gc"
  validation {
    condition     = var.naming_convention == "oss" || var.naming_convention == "gc"
    error_message = "The naming_convention field must either be 'oss' or 'gc'."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group to be imported."
  type        = string
  nullable    = false
}

variable "tags" {
  description = "The tags to associate with your network and subnets."
  type        = map(string)
  default     = {}
}

#######################
### Virtual Network ###
#######################

variable "address_space" {
  description = "The address space that is used by the virtual network."
  type        = list(string)
}

variable "vnet_peers" {
  description = "A list of remote virtual network resource IDs to use as virtual network peerings."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue(flatten([
      for resource_id in var.vnet_peers : [
        can(regex("^/subscriptions/(.+)/resourceGroups/(.+)/providers/Microsoft.Network/virtualNetworks/(.+)", resource_id))
      ]
    ]))

    error_message = "Each element within var.vnet_peers must be a valid Azure Virtual Network resource ID."
  }
}

variable "dns_servers" {
  description = "The DNS servers to be used with VNet. If no values specified, this defaults to Azure DNS."
  type        = list(string)
  default     = []
}

variable "ddos_protection_plan_id" {
  description = "The DDoS protection plan resource ID"
  type        = string
  default     = null

  validation {
    condition     = var.ddos_protection_plan_id != ""
    error_message = "The variable ddos_protection_plan_id cannot be set to an empty string"
  }
}

###############
### Subnets ###
###############

variable "subnets" {
  description = "The subnets created within the VNet"
  type = list(object({
    name             = string
    address_prefixes = list(string)

    nsg_id         = optional(string)
    route_table_id = optional(string)

    service_endpoints = optional(list(string))
    service_endpoint_policy_definitions = optional(list(object({ # No policy is created if unspecified
      name        = optional(string)
      description = optional(string)
      service     = optional(string, "Microsoft.Storage")
      scopes      = list(string)
    })))

    service_delegation_name                       = optional(string) # The name of service to delegate to
    private_endpoint_network_policies_enabled     = optional(string, "Enabled")
    private_link_service_network_policies_enabled = optional(bool, true)
  }))

  validation {
    condition = alltrue(flatten([
      for subnet in var.subnets : [
        subnet.service_endpoint_policy_definitions == null || try(contains(subnet.service_endpoints, "Microsoft.Storage"), false)
      ]
    ]))

    error_message = "Currently, Azure Service Endpoint Policy can only be used if the subnet is configured with the 'Microsoft.Storage' Service Endpoint."
  }

  validation {
    condition = alltrue(flatten([
      for subnet in var.subnets : [
        for index, policy in coalesce(subnet.service_endpoint_policy_definitions, []) : contains(["microsoft.storage", "global"], lower(policy.service))
      ]
    ]))

    error_message = "Expected service_endpoint_policy.service argument within the var.subnets to be one of [Microsoft.Storage, Global]."
  }

  validation {
    condition = length(distinct(flatten([
      for subnet in var.subnets : [
        for policy in coalesce(subnet.service_endpoint_policy_definitions, []) : policy.service
      ]
      ]))) == length(flatten([
      for subnet in var.subnets : [
        for policy in coalesce(subnet.service_endpoint_policy_definitions, []) : policy.service
      ]
    ]))

    error_message = "A service endpoint policy can only have one definition per service (Microsoft.Strorage & Global)."
  }
}

variable "subnet_nsgs" {
  type = list(object({
    subnet_name = string
    nsg_id      = string
  }))
  default = []
}

variable "subnet_route_tables" {
  type = list(object({
    subnet_name    = string
    route_table_id = string
  }))
  default = []
}
