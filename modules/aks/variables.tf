variable "name" {
  description = "Base name, used as aks-<name> and as the DNS prefix."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to deploy into."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version. Null means the current AKS default."
  type        = string
  default     = null
}

variable "sku_tier" {
  description = "Free for dev, Standard (uptime SLA) for production."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
    error_message = "sku_tier must be Free, Standard or Premium."
  }
}

variable "subnet_id" {
  description = "Subnet for the node pools."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Workspace for Container Insights."
  type        = string
}

variable "authorized_ip_ranges" {
  description = "CIDR ranges allowed to reach the Kubernetes API server."
  type        = list(string)

  validation {
    condition     = length(var.authorized_ip_ranges) > 0 && alltrue([for cidr in var.authorized_ip_ranges : can(cidrhost(cidr, 0))])
    error_message = "Set at least one valid CIDR. Leaving the API server open to the whole internet is not allowed."
  }

  validation {
    condition     = !contains(var.authorized_ip_ranges, "0.0.0.0/0")
    error_message = "0.0.0.0/0 would expose the API server to everyone."
  }
}

variable "admin_group_object_ids" {
  description = "Entra ID groups that get cluster-admin."
  type        = list(string)
  default     = []
}

variable "zones" {
  description = "Availability zones for the node pools."
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "system_node_vm_size" {
  description = "VM size for the system pool."
  type        = string
  default     = "Standard_D2s_v5"
}

variable "system_node_min_count" {
  description = "Minimum nodes in the system pool."
  type        = number
  default     = 2
}

variable "system_node_max_count" {
  description = "Maximum nodes in the system pool."
  type        = number
  default     = 3

  validation {
    condition     = var.system_node_max_count >= var.system_node_min_count
    error_message = "system_node_max_count must be >= system_node_min_count."
  }
}

variable "user_node_vm_size" {
  description = "VM size for the workload pool."
  type        = string
  default     = "Standard_D4s_v5"
}

variable "user_node_min_count" {
  description = "Minimum nodes in the workload pool."
  type        = number
  default     = 2
}

variable "user_node_max_count" {
  description = "Maximum nodes in the workload pool."
  type        = number
  default     = 6

  validation {
    condition     = var.user_node_max_count >= var.user_node_min_count
    error_message = "user_node_max_count must be >= user_node_min_count."
  }
}

variable "attach_acr" {
  description = "Grant the cluster AcrPull on acr_id."
  type        = bool
  default     = false
}

variable "acr_id" {
  description = "Container registry to pull from when attach_acr is true."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
