output "app_public_key" {
  value     = azapi_resource_action.ssh_public_key_gen_app.output.publicKey
  sensitive = true
}

output "app_private_key" {
  value     = azapi_resource_action.ssh_public_key_gen_app.output.privateKey
  sensitive = true
}

output "db_public_key" {
  value     = azapi_resource_action.ssh_public_key_gen_db.output.publicKey
  sensitive = true
}

output "db_private_key" {
  value     = azapi_resource_action.ssh_public_key_gen_db.output.privateKey
  sensitive = true
}

output "app_private_ip" {
  value = azurerm_network_interface.nic_app.private_ip_address
}

output "app_public_ip" {
  value = azurerm_public_ip.app_public_ip.ip_address
}

output "db_private_ip" {
  value = azurerm_network_interface.nic_db.private_ip_address
}
