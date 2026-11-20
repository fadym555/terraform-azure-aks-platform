output "id" {
  description = "Container registry ID."
  value       = azurerm_container_registry.this.id
}

output "login_server" {
  description = "Registry login server, e.g. myacr.azurecr.io."
  value       = azurerm_container_registry.this.login_server
}
