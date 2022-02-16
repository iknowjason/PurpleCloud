#######
#
# Special Note:  This tf file does not join the windows system to the domain
# I removed the Microsoft.Compute CustomScriptExtension & JsonADDomainExtension that were supposed to add the machine to the domain
# They were very unreliable
# The new method is using Powershell in the files/bootstrap.ps1 script
# It adds a scheduled task that checks every minute and provisions the host on the domain
#
######

locals {
  win10virtual_machine_name = var.endpoint_hostname
  win10virtual_machine_fqdn = "${local.win10virtual_machine_name}.${var.ad_domain}"
  win10custom_data_params   = "Param($RemoteHostName = \"${local.win10virtual_machine_fqdn}\", $ComputerName = \"${local.win10virtual_machine_name}\")"
  win10custom_data_content  = base64encode(join(" ", [local.win10custom_data_params, data.template_file.ps_template.rendered ]))
}

data "template_file" "ps_template" {
  template = file("${path.module}/files/bootstrap.ps1")

  vars  = {
    join_domain               = var.join_domain ? 1 : 0
    dc_ip                     = var.dc_ip
    endpoint_ad_user          = var.endpoint_ad_user
    endpoint_ad_password      = var.endpoint_ad_password
    winrm_username            = var.winrm_username
    winrm_password            = var.winrm_password
    admin_username            = var.admin_username
    admin_password            = var.admin_password
    ad_domain                 = var.ad_domain
    prefix                    = var.prefix
  }
}

resource "local_file" "debug_bootstrap_script" {
  # For inspecting the rendered powershell script as it is loaded onto endpoint through custom_data extension
  content = data.template_file.ps_template.rendered
  filename = "${path.module}/output/bootstrap-${var.endpoint_hostname}.ps1"
}


resource "azurerm_windows_virtual_machine" "win10" {

  name                          = local.win10virtual_machine_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  size                       = "Standard_DS1_v2"
  computer_name  = local.win10virtual_machine_name
  admin_username = var.admin_username
  admin_password = var.admin_password
  provision_vm_agent        = true
  custom_data    = local.win10custom_data_content
  
  network_interface_ids         = [
    azurerm_network_interface.primary.id,
  ]
  
  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "19h1-pro"
    version   = "latest"
  }

  os_disk {
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  additional_unattend_content {
      content      = "<AutoLogon><Password><Value>${var.admin_password}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.admin_username}</Username></AutoLogon>"
      setting = "AutoLogon"
  }

  additional_unattend_content {
      content      = file("${path.module}/files/FirstLogonCommands.xml")
      setting = "FirstLogonCommands"
  }
  
  depends_on = [azurerm_network_interface.primary]
}

resource "local_file" "hosts_cfg" {
  content = templatefile("${path.module}/templates/hosts.tpl",
    {
      ip    = azurerm_public_ip.win10-external.ip_address
      auser = var.admin_username
      apwd  = var.admin_password
    }
  )
  filename = "${path.module}/hosts-${var.endpoint_hostname}.cfg"
}
