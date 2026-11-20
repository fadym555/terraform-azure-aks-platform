# Prod: SLA tier, private registry, longer log retention, more headroom.
subscription_id        = "00000000-0000-0000-0000-000000000000"
project                = "shop"
environment            = "prod"
location               = "westeurope"
vnet_cidr              = "10.20.0.0/16"
log_retention_days     = 90
acr_sku                = "Premium"
aks_sku_tier           = "Standard"
authorized_ip_ranges   = ["203.0.113.0/24", "198.51.100.0/24"]
admin_group_object_ids = []
user_node_min_count    = 3
user_node_max_count    = 10

tags = {
  cost_center = "platform"
  criticality = "high"
}
