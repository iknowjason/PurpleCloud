resource "azurerm_public_ip" "win10-2-external" {
  #name                         = "${var.prefix}-win10-2${1 + count.index}-ext"
  name                         = "${var.prefix}-win10-2-ext"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  #public_ip_address_allocation = "static"
  allocation_method            = "Static"
  #count                        = "${var.vmcount}"
}

resource "azurerm_network_interface" "primary" {
  #name                    = "${var.prefix}-win10-2${1 + count.index}-int"
  name                    = "${var.prefix}-win10-2-int"
  location                = "${var.location}"
  resource_group_name     = "${var.resource_group_name}"
  internal_dns_name_label = "${var.prefix}-win10-2"
  #count                   = "${var.vmcount}"

  ip_configuration {
    name                          = "primary"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "static"
    #private_ip_address            = "10.100.30.${12 + count.index}"
    private_ip_address            = "10.100.30.12"
    #public_ip_address_id          = "${azurerm_public_ip.static.*.id[count.index]}"
    public_ip_address_id          = "${azurerm_public_ip.win10-2-external.id}"
  }
}
