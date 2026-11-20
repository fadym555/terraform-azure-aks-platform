terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

resource "azurerm_container_registry" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku

  # Pull access goes through Entra ID (AcrPull role), never the shared admin user
  admin_enabled = false

  # Closing public access needs the Premium SKU
  public_network_access_enabled = var.sku == "Premium" ? var.public_network_access_enabled : true
  zone_redundancy_enabled       = var.sku == "Premium" ? var.zone_redundancy_enabled : false

  tags = var.tags
}
