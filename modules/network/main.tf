resource "azurerm_resource_group" "network" {
  name     = "${var.resource_group_name}-${var.environment_name}"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.resource_group_name}-${var.environment_name}-net"
  address_space       = ["${var.address_space}"]
  location            = var.location
  resource_group_name = "${var.resource_group_name}-${var.environment_name}"
  dns_servers         = ["10.100.1.4"]

  depends_on = [azurerm_resource_group.network]
}

resource "azurerm_subnet" "dc-subnet" {
  name                 = "${var.resource_group_name}-${var.dcsubnet_name}-${var.environment_name}"
  resource_group_name  = "${var.resource_group_name}-${var.environment_name}"
  virtual_network_name = azurerm_virtual_network.main.name
  #address_prefix     = var.dcsubnet_prefix
  address_prefixes     = [var.dcsubnet_prefix]
}

resource "azurerm_subnet_network_security_group_association" "nsg-dc" {
  subnet_id            = azurerm_subnet.dc-subnet.id
  network_security_group_id = azurerm_network_security_group.nsg1.id

  depends_on = [azurerm_resource_group.network]
}

resource "azurerm_subnet" "waf-subnet" {
  name                 = "${var.resource_group_name}-${var.wafsubnet_name}-${var.environment_name}"
  resource_group_name  = "${var.resource_group_name}-${var.environment_name}"
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes       = [var.wafsubnet_prefix]
}

resource "azurerm_subnet" "rp-subnet" {
  name                 = "${var.resource_group_name}-${var.rpsubnet_name}-${var.environment_name}"
  resource_group_name  = "${var.resource_group_name}-${var.environment_name}"
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes       = [var.rpsubnet_prefix]
}

resource "azurerm_subnet" "user1-subnet" {
  name                 = "${var.resource_group_name}-${var.user1_subnet_name}-${var.environment_name}"
  resource_group_name  = "${var.resource_group_name}-${var.environment_name}"
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes       = [var.user1_subnet_prefix]
}

resource "azurerm_subnet" "user2-subnet" {
  name                 = "${var.resource_group_name}-${var.user2_subnet_name}-${var.environment_name}"
  resource_group_name  = "${var.resource_group_name}-${var.environment_name}"
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes       = [var.user2_subnet_prefix]
}

resource "azurerm_subnet_network_security_group_association" "nsg-is" {
  subnet_id            = azurerm_subnet.user1-subnet.id
  network_security_group_id = azurerm_network_security_group.nsg1.id

  depends_on = [azurerm_resource_group.network]
}

resource "azurerm_subnet_network_security_group_association" "nsg-is2" {
  subnet_id            = azurerm_subnet.user2-subnet.id
  network_security_group_id = azurerm_network_security_group.nsg1.id

  depends_on = [azurerm_resource_group.network]
}


resource "azurerm_subnet" "db-subnet" {
  name                 = "${var.resource_group_name}-${var.dbsubnet_name}-${var.environment_name}"
  resource_group_name  = "${var.resource_group_name}-${var.environment_name}"
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes       = [var.dbsubnet_prefix]
}
