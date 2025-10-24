locals {
  default_tags = {
    environment = "${var.project_name}"
    source      = "BeyondEdge Terraform"
    email       = "lamb2111933@student.ctu.edu.vn" # Temp
    owner       = "SCDF"
  }
}

module "base" {
  source = "./modules/base"
  providers = {
    azurerm = azurerm.scdf_poc
  }
  tags = local.default_tags

  project_name = var.project_name
  rg_location  = var.location
}

module "network" {
  source = "./modules/network"
  providers = {
    azurerm = azurerm.scdf_poc
  }
  tags = local.default_tags

  project_name    = var.project_name
  location        = module.base.location
  rg_network_name = module.base.rg_network_name
  ssh_source_ips  = var.ssh_source_ips
}

module "vm" {
  source = "./modules/vm"
  providers = {
    azurerm = azurerm.scdf_poc
  }
  tags = local.default_tags

  project_name = var.project_name
  domain_name  = var.domain_name
  location     = module.base.location
  rg_vm_id     = module.base.rg_vm_id
  rg_vm_name   = module.base.rg_vm_name

  vnet_address_space = module.network.vnet_address_space
  public_subnet_id   = module.network.public_subnet_id
  private_subnet_id  = module.network.private_subnet_id

  admin_username    = var.admin_username
  db_admin_password = var.db_admin_password
  db_usr_password   = var.db_usr_password

  image_publisher = var.image_publisher
  image_offer     = var.image_offer
  image_sku       = var.image_sku
  image_version   = var.image_version

  app_vm_size        = var.db_vm_size
  app_data_disk_size = var.app_data_disk_size
  db_vm_size         = var.db_vm_size
  db_data_disk_size  = var.db_data_disk_size
}
