variable "subscription_id" {
  description = "Azure subscription to deploy into."
  type        = string
}

variable "project" {
  description = "Short project name, lowercase letters and digits (also used in the ACR name)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{2,12}$", var.project))
    error_message = "project must be 2-12 lowercase letters or digits."
  }
}

variable "environment" {
  description = "dev, staging or prod."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging or prod."
  }
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "westeurope"
}

variable "vnet_cidr" {
  description = "Address space for the environment VNet. The AKS subnet takes the first /20."
  type        = string

  validation {
    condition     = can(cidrsubnet(var.vnet_cidr, 4, 0))
    error_message = "vnet_cidr must be a valid CIDR of /16 to /20 or so."
  }
}

variable "log_retention_days" {
  description = "Log Analytics retention."
  type        = number
  default     = 30
}

variable "acr_sku" {
  description = "Container registry SKU. Premium enables private access and zone redundancy."
  type        = string
  default     = "Standard"
}

variable "aks_sku_tier" {
  description = "Free for dev, Standard for production (uptime SLA)."
  type        = string
  default     = "Standard"
}

variable "authorized_ip_ranges" {
  description = "Networks allowed to reach the Kubernetes API (office, VPN, CI runners)."
  type        = list(string)
}

variable "admin_group_object_ids" {
  description = "Entra ID groups that get cluster-admin."
  type        = list(string)
  default     = []
}

variable "user_node_min_count" {
  description = "Minimum workload nodes."
  type        = number
  default     = 2
}

variable "user_node_max_count" {
  description = "Maximum workload nodes."
  type        = number
  default     = 6
}

variable "tags" {
  description = "Extra tags merged onto every resource."
  type        = map(string)
  default     = {}
}
