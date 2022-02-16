resource "azurerm_public_ip" "vh-external" {
  name                    = "${var.prefix}-vh-external"
  location                = var.location
  resource_group_name     = var.resource_group_name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
}

resource "azurerm_network_interface" "primary" {
  name                    = "${var.prefix}-vh-primary"
  location                = var.location
  resource_group_name     = var.resource_group_name
  internal_dns_name_label = local.virtual_machine_name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "static"
    private_ip_address            = var.vhprivate_ip_address
    public_ip_address_id          = azurerm_public_ip.vh-external.id
  }
}
