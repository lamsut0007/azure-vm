terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">=2.5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">=0.13.1"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.0.0"
    }
  }
}

# SSH keys for App VM
resource "random_pet" "ssh_key_name_app" {
  prefix    = "sshapp"
  separator = ""
}

resource "azapi_resource" "ssh_public_key_app" {
  type      = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name      = random_pet.ssh_key_name_app.id
  location  = var.location
  parent_id = var.rg_vm_id
}

resource "azapi_resource_action" "ssh_public_key_gen_app" {
  type        = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id = azapi_resource.ssh_public_key_app.id
  action      = "generateKeyPair"
  method      = "POST"

  response_export_values = ["publicKey", "privateKey"]
}

# SSH key for Database VM
resource "random_pet" "ssh_key_name_db" {
  prefix    = "sshdb"
  separator = ""
}

resource "azapi_resource" "ssh_public_key_db" {
  type      = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name      = random_pet.ssh_key_name_db.id
  location  = var.location
  parent_id = var.rg_vm_id
}

resource "azapi_resource_action" "ssh_public_key_gen_db" {
  type        = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id = azapi_resource.ssh_public_key_db.id
  action      = "generateKeyPair"
  method      = "POST"

  response_export_values = ["publicKey", "privateKey"]
}

# Database VM
resource "azurerm_network_interface" "nic_db" {
  name                = "${var.project_name}-nic-db"
  location            = var.location
  resource_group_name = var.rg_vm_name
  ip_configuration {
    name                          = "ipconfig-db"
    subnet_id                     = var.private_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "db_vm" {
  name                = "${var.project_name}-vm-db"
  location            = var.location
  resource_group_name = var.rg_vm_name
  network_interface_ids = [
    azurerm_network_interface.nic_db.id
  ]
  size                            = var.db_vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  admin_ssh_key {
    username   = var.admin_username
    public_key = azapi_resource_action.ssh_public_key_gen_db.output.publicKey
  }
  os_disk {
    name                 = "${var.project_name}-osdisk-db"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = "latest"
  }
  custom_data = base64encode(
    templatefile("${path.module}/setup/db.tpl", {
      address_space     = var.vnet_address_space
      db_admin_password = var.db_admin_password
      db_usr_password   = var.db_usr_password
    })
  )
  tags = var.tags
}

resource "azurerm_managed_disk" "db_data_disk" {
  name                 = "${var.project_name}-db-data-disk"
  location             = var.location
  resource_group_name  = var.rg_vm_name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.db_data_disk_size
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "db_disk_attach" {
  managed_disk_id    = azurerm_managed_disk.db_data_disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.db_vm.id
  lun                = 0
  caching            = "ReadWrite"
}

# App VM
resource "azurerm_network_interface" "nic_app" {
  name                = "${var.project_name}-nic-app"
  location            = var.location
  resource_group_name = var.rg_vm_name
  ip_configuration {
    name                          = "ipconfig-app"
    subnet_id                     = var.public_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.app_public_ip.id
  }
  tags = var.tags
}

resource "azurerm_public_ip" "app_public_ip" {
  name                = "${var.project_name}-app-public-ip"
  location            = var.location
  resource_group_name = var.rg_vm_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_linux_virtual_machine" "app_vm" {
  name                = "${var.project_name}-vm-app"
  location            = var.location
  resource_group_name = var.rg_vm_name
  network_interface_ids = [
    azurerm_network_interface.nic_app.id
  ]
  size                            = var.app_vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  admin_ssh_key {
    username   = var.admin_username
    public_key = azapi_resource_action.ssh_public_key_gen_app.output.publicKey
  }
  os_disk {
    name                 = "${var.project_name}-osdisk-app"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }
  custom_data = base64encode(
    templatefile("${path.module}/setup/app.tpl", {
      project_name = var.project_name
    })
  )
  tags = var.tags
}

resource "azurerm_managed_disk" "app_data_disk" {
  name                 = "${var.project_name}-app-data-disk"
  location             = var.location
  resource_group_name  = var.rg_vm_name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.app_data_disk_size
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "app_disk_attach" {
  managed_disk_id    = azurerm_managed_disk.app_data_disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.app_vm.id
  lun                = 0
  caching            = "ReadWrite"
}

resource "time_sleep" "wait_for_custom_data" {
  depends_on      = [azurerm_linux_virtual_machine.app_vm]
  create_duration = "300s"
}

resource "null_resource" "upload_db_ssh_key" {
  depends_on = [azurerm_linux_virtual_machine.app_vm, azurerm_linux_virtual_machine.db_vm]

  provisioner "remote-exec" {
    inline = [
      "echo '${azapi_resource_action.ssh_public_key_gen_db.output.privateKey}' | sudo tee /home/${var.admin_username}/db_key.pem > /dev/null",
      "sudo chmod 600 /home/${var.admin_username}/db_key.pem",
      "sudo chown ${var.admin_username}:${var.admin_username} /home/${var.admin_username}/db_key.pem"
    ]

    connection {
      type        = "ssh"
      host        = azurerm_linux_virtual_machine.app_vm.public_ip_address
      user        = var.admin_username
      private_key = azapi_resource_action.ssh_public_key_gen_app.output.privateKey
    }
  }
}

resource "null_resource" "upload_ssl_files" {
  depends_on = [time_sleep.wait_for_custom_data]

  provisioner "file" {
    source      = "${path.root}/certs/"
    destination = "/tmp/"

    connection {
      type        = "ssh"
      host        = azurerm_linux_virtual_machine.app_vm.public_ip_address
      user        = var.admin_username
      private_key = azapi_resource_action.ssh_public_key_gen_app.output.privateKey
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/pki/tls/private",
      "sudo mkdir -p /tmp/ca",
      "sudo chmod 777 /tmp/ca",

      "CRT_FILE=$(sudo find /tmp -type f -name '*.crt' -printf '%T@ %p\n' | sort -nr | head -n 1 | awk '{print $2}')",
      "PEM_FILE=$(sudo find /tmp -type f -name '*.pem' -printf '%T@ %p\n' | sort -nr | head -n 1 | awk '{print $2}')",

      "if [ -n \"$CRT_FILE\" ]; then sudo cp \"$CRT_FILE\" /etc/pki/tls/private/${var.project_name}.crt; fi",
      "if [ -n \"$PEM_FILE\" ]; then sudo cp \"$PEM_FILE\" /etc/pki/tls/private/${var.project_name}.pem; fi",

      "sudo chmod 644 /etc/pki/tls/private/${var.project_name}.crt",
      "sudo chmod 600 /etc/pki/tls/private/${var.project_name}.pem"
    ]

    connection {
      type        = "ssh"
      host        = azurerm_linux_virtual_machine.app_vm.public_ip_address
      user        = var.admin_username
      private_key = azapi_resource_action.ssh_public_key_gen_app.output.privateKey
    }
  }
}

resource "null_resource" "upload_ca_file" {
  depends_on = [null_resource.upload_ssl_files]

  provisioner "file" {
    source      = "${path.root}/ca/"
    destination = "/tmp/ca/"

    connection {
      type        = "ssh"
      host        = azurerm_linux_virtual_machine.app_vm.public_ip_address
      user        = var.admin_username
      private_key = azapi_resource_action.ssh_public_key_gen_app.output.privateKey
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/ssl/certs",

      "CA_FILE=$(sudo find /tmp/ca -type f -name '*.crt' -printf '%T@ %p\n' | sort -nr | head -n 1 | awk '{print $2}')",
      "if [ -n \"$CA_FILE\" ]; then sudo cp \"$CA_FILE\" /etc/ssl/certs/${var.project_name}_ca.crt; fi",

      "sudo chmod 644 /etc/ssl/certs/${var.project_name}_ca.crt",
    ]

    connection {
      type        = "ssh"
      host        = azurerm_linux_virtual_machine.app_vm.public_ip_address
      user        = var.admin_username
      private_key = azapi_resource_action.ssh_public_key_gen_app.output.privateKey
    }
  }
}

resource "null_resource" "apache_setup" {
  depends_on = [null_resource.upload_ssl_files]

  provisioner "file" {
    source      = "${path.module}/setup/"
    destination = "/tmp/"

    connection {
      type        = "ssh"
      host        = azurerm_linux_virtual_machine.app_vm.public_ip_address
      user        = var.admin_username
      private_key = azapi_resource_action.ssh_public_key_gen_app.output.privateKey
    }
  }

  # Configure Apache
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/httpd/conf",
      "sudo mkdir -p /etc/httpd/conf.d",
      "sudo cp /tmp/httpd.conf /etc/httpd/conf/httpd.conf",
      "sudo cp /tmp/ssl.conf /etc/httpd/conf.d/ssl.conf",

      "sudo sed -i \"s|your-domain|${var.domain_name}|g\" /etc/httpd/conf/httpd.conf",
      "sudo sed -i \"s|your-project|${var.project_name}|g\" /etc/httpd/conf/httpd.conf",
      "sudo sed -i \"s|your-domain|${var.domain_name}|g\" /etc/httpd/conf.d/ssl.conf",
      "sudo sed -i \"s|your-project|${var.project_name}|g\" /etc/httpd/conf.d/ssl.conf",

      "sudo apachectl configtest && sudo systemctl reload httpd"
    ]

    connection {
      type        = "ssh"
      host        = azurerm_linux_virtual_machine.app_vm.public_ip_address
      user        = var.admin_username
      private_key = azapi_resource_action.ssh_public_key_gen_app.output.privateKey
    }
  }
}
