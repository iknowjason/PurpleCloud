resource "azurerm_network_security_group" "nsg1" {
  name                = "${var.resource_group_name}-nsg1"
  location            = var.location
  resource_group_name = "${var.resource_group_name}-${var.environment_name}"

  security_rule {
    name                       = "allow-rdp"
    description                = "Allow Remote Desktop"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.src_ip 
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-winrms"
    description                = "Windows Remote Managment (HTTPS-In)"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5986"
    source_address_prefix      = var.src_ip 
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-winrm"
    description                = "Windows Remote Managment (HTTP-In)"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5985"
    source_address_prefix      = var.src_ip 
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-ssh"
    description                = "Allow SSH (SSH-In)"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.src_ip 
    destination_address_prefix = "*"
  }


security_rule {
    name                       = "allow-HTTPS"
    description                = "Permit HTTPS (HTTPS-In)"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.src_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-Spark"
    description                = "Permit Spark (Spark-In)"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = var.src_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-KQL"
    description                = "Permit KQL (KQL-In)"
    priority                   = 106
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8088"
    source_address_prefix      = var.src_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Zookeeper"
    description                = "Permit Zookeeper (Zookeeper-In)"
    priority                   = 107
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2181"
    source_address_prefix      = var.src_ip
    destination_address_prefix = "*"
  }


  security_rule {
    name                       = "allow-HTTPS-8889"
    description                = "Permit HTTPS Port 8889 (HTTPS-In)"
    priority                   = 108
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8889"
    source_address_prefix      = var.src_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-agent"
    description                = "Permit Agent (8000-In)"
    priority                   = 109
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000"
    source_address_prefix      = var.src_ip
    destination_address_prefix = "*"
  }

  depends_on = [azurerm_resource_group.network]
}
