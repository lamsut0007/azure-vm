output "app_public_ip" {
  value = module.vm.app_public_ip
}

output "app_private_ip" {
  value = module.vm.app_private_ip
}

output "db_private_ip" {
  value = module.vm.db_private_ip
}

output "app_public_key" {
  value     = module.vm.app_public_key
  sensitive = true
}

output "app_private_key" {
  value     = module.vm.app_private_key
  sensitive = true
}

output "db_public_key" {
  value     = module.vm.db_public_key
  sensitive = true
}

output "db_private_key" {
  value     = module.vm.db_private_key
  sensitive = true
}
