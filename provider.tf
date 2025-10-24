terraform {
  required_version = ">= 1.11.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">=0.13.1"
    }
  }

  backend "local" {
  }
}

provider "azurerm" {
  features {}
  alias           = "scdf_poc"
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  # client_id       = var.client_id
  # client_secret   = var.client_secret
}
