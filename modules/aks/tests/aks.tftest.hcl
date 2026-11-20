mock_provider "azurerm" {}

variables {
  name                       = "demo"
  location                   = "westeurope"
  resource_group_name        = "rg-demo"
  subnet_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo/providers/Microsoft.Network/virtualNetworks/vnet-demo/subnets/snet-aks"
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo/providers/Microsoft.OperationalInsights/workspaces/log-demo"
  authorized_ip_ranges       = ["203.0.113.0/24"]
}

run "secure_by_default" {
  command = plan

  assert {
    condition     = azurerm_kubernetes_cluster.this.local_account_disabled
    error_message = "Local (static) accounts must be disabled."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this.workload_identity_enabled && azurerm_kubernetes_cluster.this.oidc_issuer_enabled
    error_message = "Workload identity must be on."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this.network_profile[0].network_policy == "calico"
    error_message = "A network policy engine must be enabled."
  }

  assert {
    condition     = tolist(azurerm_kubernetes_cluster.this.api_server_access_profile[0].authorized_ip_ranges) == ["203.0.113.0/24"]
    error_message = "API server must be restricted to the authorized ranges."
  }
}

run "separates_system_and_user_pools" {
  command = plan

  assert {
    condition     = azurerm_kubernetes_cluster.this.default_node_pool[0].only_critical_addons_enabled
    error_message = "System pool should only run critical add-ons."
  }

  assert {
    condition     = azurerm_kubernetes_cluster_node_pool.user.mode == "User"
    error_message = "Workloads need a dedicated user pool."
  }
}

run "acr_pull_only_when_requested" {
  command = plan

  assert {
    condition     = length(azurerm_role_assignment.acr_pull) == 0
    error_message = "No AcrPull assignment expected when attach_acr is false."
  }
}

run "rejects_open_api_server" {
  command = plan

  variables {
    authorized_ip_ranges = ["0.0.0.0/0"]
  }

  expect_failures = [var.authorized_ip_ranges]
}

run "rejects_inverted_autoscaling_bounds" {
  command = plan

  variables {
    user_node_min_count = 5
    user_node_max_count = 2
  }

  expect_failures = [var.user_node_max_count]
}
