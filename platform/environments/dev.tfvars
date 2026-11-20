# Dev: cheap and small. Replace subscription_id and the IP ranges with your own.
subscription_id      = "00000000-0000-0000-0000-000000000000"
project              = "shop"
environment          = "dev"
location             = "westeurope"
vnet_cidr            = "10.10.0.0/16"
log_retention_days   = 30
acr_sku              = "Standard"
aks_sku_tier         = "Free"
authorized_ip_ranges = ["203.0.113.0/24"]
user_node_min_count  = 1
user_node_max_count  = 3
