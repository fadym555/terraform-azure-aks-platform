output "resource_group_name" {
  description = "Resource group holding the platform."
  value       = azurerm_resource_group.this.name
}

output "aks_name" {
  description = "AKS cluster name (az aks get-credentials -n <this>)."
  value       = module.aks.name
}

output "acr_login_server" {
  description = "Registry to push images to."
  value       = module.acr.login_server
}

output "oidc_issuer_url" {
  description = "Use this when federating GitHub Actions or workloads with Entra ID."
  value       = module.aks.oidc_issuer_url
}
