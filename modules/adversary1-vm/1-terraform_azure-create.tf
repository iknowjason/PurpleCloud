

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
  name                = "adversary1-PublicIP"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
}

/*output "public_ip_address" {
    value = data.azurerm_public_ip.myterraformpublicip.ip_address
}*/

# Create network interface
resource "azurerm_network_interface" "adversarynic" {
  name                    = "adversaryNIC"
  location                = var.location
  resource_group_name     = var.resource_group_name
  internal_dns_name_label = "${var.prefix}-adversary1"

  ip_configuration {
    name                          = "adversarynic"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "static"
    private_ip_address            = "10.100.40.10"
    #public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
    public_ip_address_id = azurerm_public_ip.myterraformpublicip.id

  }
}

# Connect the security group to the network interface
#resource "azurerm_network_interface_security_group_association" "example" {
#    network_interface_id      = azurerm_network_interface.myterraformnic.id
#    network_security_group_id = azurerm_network_security_group.myterraformnsg.id
#}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group_name = "${var.resource_group_name}"
    #resource_group = azurerm_resource_group.myterraformgroup.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
  name                = "diag${random_id.randomId.hex}"
  resource_group_name = var.resource_group_name
  #resource_group_name         = azurerm_resource_group.myterraformgroup.name
  location = var.location
  #location                    = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  #    tags = {
  #        environment = "Terraform Demo"
  #    }
}

# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# Enable if you want to see the SSH key - It is written to a file
#output "tls_private_key" { value = "${tls_private_key.example_ssh.private_key_pem}" }

# Create virtual machine
resource "azurerm_linux_virtual_machine" "myterraformvm" {
  name                  = "adversary-devops1"
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.adversarynic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "adversary-devops1"
  admin_username                  = "aria"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "aria"
    public_key = tls_private_key.example_ssh.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
  }

  tags = {
    environment = "Terraform Demo"
  }

}

# write public IP address of Linux host to file
resource "local_file" "hosts_cfg" {
  content = templatefile("${path.module}/templates/hosts.tpl",
    {
      ip    = "${azurerm_public_ip.myterraformpublicip.ip_address}"
      auser = "aria"
    }
  )
  filename = "${path.module}/hosts.cfg"

}

# write ssh key to file
resource "local_file" "ssh_key" {
  content         = tls_private_key.example_ssh.private_key_pem
  filename        = "${path.module}/ssh_key.pem"
  file_permission = "0700"
}


# enable if you want to see host IP address details
#output "host_ip_address" { value = "${azurerm_public_ip.myterraformpublicip}" }
