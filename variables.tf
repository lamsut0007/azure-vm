# Azure Resource Group and Subscription Variables
variable "subscription_id" {
  description = "The ID of the Azure subscription where the resources will be created."
  type        = string
}
variable "tenant_id" {
  description = "The ID of the Azure tenant where the resources will be created."
  type        = string
}
# variable "client_id" {
#   description = "The client ID of the service principal used for authentication."
#   type        = string
# }
# variable "client_secret" {
#   description = "The client secret of the service principal used for authentication."
#   type        = string
#   sensitive   = true
# }

# Base Variables
variable "project_name" {
  description = "SCDF project name."
  type        = string
}
variable "domain_name" {
  description = "The domain name for the application"
  type        = string
  default     = "scdf-uat.com.sg"
}
variable "location" {
  description = "The Azure region where the resource groups will be created."
  type        = string
  default     = "southeastasia"
}

# Network Variables
variable "ssh_source_ips" {
  description = "List of trusted SSH source IPs."
  type        = list(string)
  default = [
    "115.75.101.152/32",
    "115.78.6.171/32",
    "115.78.6.138/32"
  ]
}

# VM Variables
variable "admin_username" {
  description = "Admin username for the VMs"
  type        = string
  default     = "azureuser"
}
variable "db_admin_password" {
  description = "Password for the default PostgreSQL 'postgres' user"
  type        = string
  sensitive   = true
}
variable "db_usr_password" {
  description = "Password for the database user used by the application"
  type        = string
  sensitive   = true
}

variable "image_publisher" {
  description = "The publisher of the VM image"
  type        = string
  default     = "almalinux"
}
variable "image_offer" {
  description = "The offer of the VM image"
  type        = string
  default     = "almalinux-x86_64"
}
variable "image_sku" {
  description = "The SKU of the VM image"
  type        = string
  default     = "9-gen2"
}
variable "image_version" {
  description = "The version of the VM image"
  type        = string
  default     = "9.6.202505220"
}

variable "app_vm_size" {
  description = "The size of the application VM"
  type        = string
  default     = "Standard_B2s"
}
variable "app_data_disk_size" {
  description = "The size of the application data disk in GB"
  type        = number
  default     = 30
}
variable "db_vm_size" {
  description = "The size of the database VM"
  type        = string
  default     = "Standard_B2s"
}
variable "db_data_disk_size" {
  description = "The size of the database data disk in GB"
  type        = number
  default     = 30
}
