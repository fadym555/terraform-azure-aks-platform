terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# User-assigned identities survive cluster rebuilds, so role assignments
# (ACR pull, Key Vault, DNS) don't have to be redone if the cluster is replaced.
resource "azurerm_user_assigned_identity" "control_plane" {
  name                = "id-aks-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "kubelet" {
  name                = "id-aks-${var.name}-kubelet"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# The control plane needs to be able to attach the kubelet identity to nodes
resource "azurerm_role_assignment" "control_plane_identity_operator" {
  scope                = azurerm_user_assigned_identity.kubelet.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.control_plane.principal_id
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = "aks-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.name
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier

  automatic_upgrade_channel = "patch"
  node_os_upgrade_channel   = "NodeImage"

  # Identity: Entra ID only, no static kubeconfig credentials
  local_account_disabled            = true
  role_based_access_control_enabled = true
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  azure_policy_enabled              = true

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    admin_group_object_ids = var.admin_group_object_ids
  }

  # The API server only answers known networks
  api_server_access_profile {
    authorized_ip_ranges = var.authorized_ip_ranges
  }

  # System pool runs only cluster add-ons; workloads go to the user pool
  default_node_pool {
    name                         = "system"
    vm_size                      = var.system_node_vm_size
    vnet_subnet_id               = var.subnet_id
    zones                        = var.zones
    auto_scaling_enabled         = true
    min_count                    = var.system_node_min_count
    max_count                    = var.system_node_max_count
    only_critical_addons_enabled = true
    temporary_name_for_rotation  = "systemtmp"

    upgrade_settings {
      max_surge = "33%"
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.control_plane.id]
  }

  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.kubelet.client_id
    object_id                 = azurerm_user_assigned_identity.kubelet.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.kubelet.id
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "calico"
    load_balancer_sku   = "standard"
  }

  oms_agent {
    log_analytics_workspace_id      = var.log_analytics_workspace_id
    msi_auth_for_monitoring_enabled = true
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [default_node_pool[0].node_count]
  }

  depends_on = [azurerm_role_assignment.control_plane_identity_operator]
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  mode                  = "User"
  vm_size               = var.user_node_vm_size
  vnet_subnet_id        = var.subnet_id
  zones                 = var.zones
  auto_scaling_enabled  = true
  min_count             = var.user_node_min_count
  max_count             = var.user_node_max_count

  upgrade_settings {
    max_surge = "33%"
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [node_count]
  }
}

# Let the kubelet pull from ACR with its managed identity
resource "azurerm_role_assignment" "acr_pull" {
  count = var.attach_acr ? 1 : 0

  scope                            = var.acr_id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_user_assigned_identity.kubelet.principal_id
  skip_service_principal_aad_check = true
}
