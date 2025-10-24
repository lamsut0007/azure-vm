output "location" {
  description = "The location of the resource groups"
  value       = azurerm_resource_group.rg_network.location
}

output "rg_network_id" {
  description = "The ID of the network resource group"
  value       = azurerm_resource_group.rg_network.id
}

output "rg_network_name" {
  description = "The name of the network resource group"
  value       = azurerm_resource_group.rg_network.name
}

output "rg_vm_id" {
  description = "The ID of the VM resource group"
  value       = azurerm_resource_group.rg_vm.id
}

output "rg_vm_name" {
  description = "The name of the VM resource group"
  value       = azurerm_resource_group.rg_vm.name
}
