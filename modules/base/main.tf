terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

resource "azurerm_resource_group" "rg_network" {
  name     = "${var.project_name}-network-rg"
  location = var.rg_location
  tags     = var.tags
}

resource "azurerm_resource_group" "rg_vm" {
  name     = "${var.project_name}-vm-rg"
  location = var.rg_location
  tags     = var.tags
}
