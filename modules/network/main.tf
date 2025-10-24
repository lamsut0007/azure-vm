terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.project_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.rg_network_name
  tags                = var.tags
}

# Public Subnet
resource "azurerm_subnet" "public_subnet" {
  name                 = "${var.project_name}-subnet-public"
  resource_group_name  = var.rg_network_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "nsg_public" {
  name                = "${var.project_name}-nsg-public"
  location            = var.location
  resource_group_name = var.rg_network_name
  tags                = var.tags

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-https"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-socket"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8085"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-ssh-from-specified"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.ssh_source_ips
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-other-inbound"
    priority                   = 400
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "public_assoc" {
  subnet_id                 = azurerm_subnet.public_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg_public.id
}

resource "azurerm_route_table" "public_rt" {
  name                = "${var.project_name}-rt-public"
  location            = var.location
  resource_group_name = var.rg_network_name
  tags                = var.tags
}

resource "azurerm_route" "public_internet_route" {
  name                = "public-internet-route"
  resource_group_name = var.rg_network_name
  route_table_name    = azurerm_route_table.public_rt.name
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "Internet"
}

resource "azurerm_subnet_route_table_association" "public_rt_assoc" {
  subnet_id      = azurerm_subnet.public_subnet.id
  route_table_id = azurerm_route_table.public_rt.id
}

# Private Subnet
resource "azurerm_subnet" "private_subnet" {
  name                 = "${var.project_name}-subnet-private"
  resource_group_name  = var.rg_network_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "nat_ip" {
  name                = "${var.project_name}-nat-ip"
  location            = var.location
  resource_group_name = var.rg_network_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway" "nat_gw" {
  name                = "${var.project_name}-nat-gateway"
  location            = var.location
  resource_group_name = var.rg_network_name
  sku_name            = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "nat_ip_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gw.id
  public_ip_address_id = azurerm_public_ip.nat_ip.id
}

resource "azurerm_subnet_nat_gateway_association" "private_nat_assoc" {
  subnet_id      = azurerm_subnet.private_subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat_gw.id
}

resource "azurerm_network_security_group" "nsg_private" {
  name                = "${var.project_name}-nsg-private"
  location            = var.location
  resource_group_name = var.rg_network_name
  tags                = var.tags

  security_rule {
    name                       = "allow-ssh-from-app"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "10.0.2.0/24"
  }

  security_rule {
    name                       = "allow-postgres-from-app"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "10.0.2.0/24"
  }

  security_rule {
    name                       = "deny-other-inbound"
    priority                   = 400
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "private_assoc" {
  subnet_id                 = azurerm_subnet.private_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg_private.id
}

resource "azurerm_route_table" "private_rt" {
  name                = "${var.project_name}-rt-private"
  location            = var.location
  resource_group_name = var.rg_network_name
  tags                = var.tags
}

resource "azurerm_route" "private_default_internet" {
  name                = "default-to-internet"
  resource_group_name = var.rg_network_name
  route_table_name    = azurerm_route_table.private_rt.name
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "Internet"
}

resource "azurerm_subnet_route_table_association" "private_rt_assoc" {
  subnet_id      = azurerm_subnet.private_subnet.id
  route_table_id = azurerm_route_table.private_rt.id
}
