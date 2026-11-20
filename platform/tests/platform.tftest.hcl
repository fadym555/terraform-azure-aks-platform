# The kubelet identity only exists after apply, so give the mock a realistic one at plan time
mock_provider "azurerm" {
  mock_resource "azurerm_kubernetes_cluster" {
    override_during = plan
    defaults = {
      kubelet_identity = [{
        client_id                 = "00000000-0000-0000-0000-000000000001"
        object_id                 = "00000000-0000-0000-0000-000000000002"
        user_assigned_identity_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mc-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/aks-agentpool"
      }]
    }
  }
}

run "prod_values_plan_cleanly" {
  command = plan

  variables {
    subscription_id      = "00000000-0000-0000-0000-000000000000"
    project              = "shop"
    environment          = "prod"
    vnet_cidr            = "10.20.0.0/16"
    authorized_ip_ranges = ["203.0.113.0/24"]
  }

  assert {
    condition     = azurerm_resource_group.this.name == "rg-shop-prod"
    error_message = "Resource group name should follow rg-<project>-<environment>."
  }

  assert {
    condition     = azurerm_resource_group.this.tags["managed_by"] == "terraform" && azurerm_resource_group.this.tags["environment"] == "prod"
    error_message = "Standard tags are missing."
  }
}

run "rejects_unknown_environment" {
  command = plan

  variables {
    subscription_id      = "00000000-0000-0000-0000-000000000000"
    project              = "shop"
    environment          = "qa"
    vnet_cidr            = "10.20.0.0/16"
    authorized_ip_ranges = ["203.0.113.0/24"]
  }

  expect_failures = [var.environment]
}

run "rejects_project_name_that_breaks_acr" {
  command = plan

  variables {
    subscription_id      = "00000000-0000-0000-0000-000000000000"
    project              = "My-Shop"
    environment          = "dev"
    vnet_cidr            = "10.10.0.0/16"
    authorized_ip_ranges = ["203.0.113.0/24"]
  }

  expect_failures = [var.project]
}
