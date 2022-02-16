resource "azurerm_public_ip" "win10-external" {
  name                = "${var.prefix}-${var.endpoint_hostname}-ext"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "primary" {
  name                = "${var.prefix}-${var.endpoint_hostname}-int"
  location            = var.location
  resource_group_name = var.resource_group_name
  internal_dns_name_label = "${var.prefix}-${var.endpoint_hostname}"

  ip_configuration {
    name                          = "primary"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "static"
    private_ip_address = var.endpoint_ip
    public_ip_address_id = azurerm_public_ip.win10-external.id

  }
}
