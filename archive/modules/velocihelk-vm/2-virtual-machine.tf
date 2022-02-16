locals {
  virtual_machine_name = "${var.prefix}-velocihelk"
}

# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
    algorithm = "RSA"
    rsa_bits = 4096
}
# Enable if you want to see the SSH key - It is written to a file
output "tls_private_key" { value = tls_private_key.example_ssh.private_key_pem }

resource "azurerm_linux_virtual_machine" "vh_vm" {
  name                          = local.virtual_machine_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  network_interface_ids         = [azurerm_network_interface.primary.id]
  size                       = "Standard_DS3_v2"
  admin_username		= "helk"
  disable_password_authentication = true

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name              = "${local.virtual_machine_name}-disk1"
    caching           = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb	= 100
  }

  admin_ssh_key {
    username       = "helk"
    public_key     = tls_private_key.example_ssh.public_key_openssh
  }


  tags = {
    environment = "Velociraptor HELK Prod"
  }

}

# write public IP address of Linux host to file
resource "local_file" "hosts_cfg" {
    content = templatefile("${path.module}/templates/hosts.tpl",
        {
        ip = azurerm_public_ip.vh-external.ip_address
        huser = "helk"
        }
    )
    filename = "${path.module}/hosts.cfg"

}

# write ssh key to file
resource "local_file" "ssh_key" {
    content = tls_private_key.example_ssh.private_key_pem
    filename = "${path.module}/ssh_key.pem"
    file_permission = "0700"
}
