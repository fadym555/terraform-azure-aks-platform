mock_provider "azurerm" {}

variables {
  name                = "demo"
  location            = "westeurope"
  resource_group_name = "rg-demo"
  address_space       = ["10.20.0.0/16"]
  subnets = {
    aks = { address_prefix = "10.20.0.0/20" }
    app = { address_prefix = "10.20.16.0/24", service_endpoints = ["Microsoft.KeyVault"] }
  }
}

run "one_nsg_per_subnet" {
  command = plan

  assert {
    condition     = length(azurerm_subnet.this) == 2
    error_message = "Expected one subnet per entry in var.subnets."
  }

  assert {
    condition     = length(azurerm_network_security_group.this) == length(azurerm_subnet.this)
    error_message = "Every subnet must get its own NSG."
  }

  assert {
    condition     = azurerm_subnet.this["app"].service_endpoints == toset(["Microsoft.KeyVault"])
    error_message = "Service endpoints were not passed through."
  }
}

run "nsgs_block_internet_inbound" {
  command = plan

  assert {
    condition = alltrue([
      for nsg in azurerm_network_security_group.this :
      anytrue([for rule in nsg.security_rule : rule.access == "Deny" && rule.direction == "Inbound" && rule.source_address_prefix == "Internet"])
    ])
    error_message = "Every NSG must deny inbound traffic from the internet."
  }
}

run "rejects_invalid_cidr" {
  command = plan

  variables {
    address_space = ["10.20.0.0/33"]
  }

  expect_failures = [var.address_space]
}

run "rejects_bad_name" {
  command = plan

  variables {
    name = "Bad_Name!"
  }

  expect_failures = [var.name]
}
