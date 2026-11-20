variable "name" {
  description = "Base name, e.g. myapp-prod. Used as vnet-<name>."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,40}$", var.name))
    error_message = "name must be 3-40 characters of lowercase letters, digits and dashes."
  }
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to deploy into."
  type        = string
}

variable "address_space" {
  description = "VNet address space, e.g. [\"10.20.0.0/16\"]."
  type        = list(string)

  validation {
    condition     = length(var.address_space) > 0 && alltrue([for cidr in var.address_space : can(cidrhost(cidr, 0))])
    error_message = "address_space must contain at least one valid CIDR block."
  }
}

variable "subnets" {
  description = "Subnets keyed by short name (snet-<key>)."
  type = map(object({
    address_prefix    = string
    service_endpoints = optional(list(string), [])
  }))

  validation {
    condition     = alltrue([for s in values(var.subnets) : can(cidrhost(s.address_prefix, 0))])
    error_message = "Every subnet needs a valid CIDR address_prefix."
  }
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
