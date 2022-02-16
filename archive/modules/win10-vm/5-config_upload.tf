resource "null_resource" "velociraptor-config_upload" {

  ## Run this module is var.install_agent boolean is true
  count = var.install_agent ? 1 : 0

  ### upload velociraptor client config
  provisioner "file" {
    source      = "${path.module}/files/Velociraptor.config.yaml"
    destination = "C:/Program Files/Velociraptor/Velociraptor.config.yaml"
    connection {
      host     = azurerm_public_ip.win10-external.ip_address
      type     = "winrm"
      user     = var.admin_username
      password = var.admin_password
      timeout  = "15m"
      https    = true
      port     = "5986"
      insecure = true
    }
  }

depends_on = [null_resource.provision-sec_tools]

}
