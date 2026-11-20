terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # Remote state in Azure Storage, configured per environment at init time:
  #   terraform init -backend-config=environments/prod.backend.hcl
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

locals {
  name = "${var.project}-${var.environment}"
  tags = merge(var.tags, {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  })
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name}"
  location = var.location
  tags     = local.tags
}

module "monitoring" {
  source = "../modules/monitoring"

  name                = local.name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  retention_in_days   = var.log_retention_days
  tags                = local.tags
}

module "network" {
  source = "../modules/network"

  name                = local.name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.vnet_cidr]
  subnets = {
    aks = { address_prefix = cidrsubnet(var.vnet_cidr, 4, 0) }
  }
  tags = local.tags
}

module "acr" {
  source = "../modules/acr"

  name                          = "acr${var.project}${var.environment}"
  location                      = azurerm_resource_group.this.location
  resource_group_name           = azurerm_resource_group.this.name
  sku                           = var.acr_sku
  public_network_access_enabled = var.acr_sku != "Premium"
  zone_redundancy_enabled       = var.acr_sku == "Premium"
  tags                          = local.tags
}

module "aks" {
  source = "../modules/aks"

  name                       = local.name
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  sku_tier                   = var.aks_sku_tier
  subnet_id                  = module.network.subnet_ids["aks"]
  log_analytics_workspace_id = module.monitoring.id
  authorized_ip_ranges       = var.authorized_ip_ranges
  admin_group_object_ids     = var.admin_group_object_ids
  user_node_min_count        = var.user_node_min_count
  user_node_max_count        = var.user_node_max_count
  attach_acr                 = true
  acr_id                     = module.acr.id
  tags                       = local.tags
}
