locals {
  win101virtual_machine_name = var.endpoint1_machine_name
  win101virtual_machine_fqdn = "${local.win101virtual_machine_name}.${var.active_directory_domain}"
  win101custom_data_params   = "Param($RemoteHostName = \"${local.win101virtual_machine_fqdn}\", $ComputerName = \"${local.win101virtual_machine_name}\")"
  win101custom_data_content  = "${local.win101custom_data_params} ${file("${path.module}/files/winrm.ps1")}"
}

resource "azurerm_availability_set" "isavailabilityset" {
  name                         = "isavailabilityset"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  platform_fault_domain_count  = 3
  platform_update_domain_count = 5
  managed                      = true
}

resource "azurerm_virtual_machine" "win10-1" {
  name                          = local.win101virtual_machine_name
  location                      = var.location
  availability_set_id           = azurerm_availability_set.isavailabilityset.id
  resource_group_name           = var.resource_group_name
  #network_interface_ids         = ["${element(azurerm_network_interface.primary.*.id, count.index)}"]
  network_interface_ids         = [element(azurerm_network_interface.primary.*.id, count.index)]
  vm_size                       = "Standard_DS1_v2"
  delete_os_disk_on_termination = true
  count                         = var.vmcount

  storage_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "19h1-pro"
    version   = "latest"
  }

  storage_os_disk {
    name              = "win10-disk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = local.win101virtual_machine_name
    admin_username = var.admin_username
    admin_password = var.admin_password
    custom_data    = local.win101custom_data_content
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = false

    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "AutoLogon"
      content      = "<AutoLogon><Password><Value>${var.admin_password}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.admin_username}</Username></AutoLogon>"
    }

    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "FirstLogonCommands"
      content      = file("${path.module}/files/FirstLogonCommands.xml")
    }
  }
  depends_on = [azurerm_network_interface.primary]
}

resource "local_file" "hosts_cfg" {
  content = templatefile("${path.module}/templates/hosts.tpl",
    {
      ip    = azurerm_public_ip.win10-1-external.ip_address
      auser = var.admin_username
      apwd  = var.admin_password
    }
  )
  filename = "${path.module}/hosts.cfg"
}
