resource "null_resource" "provision-sec_tools" {

  ## Run this module is var.install_agent boolean is true
  count = var.install_agent ? 1 : 0

  provisioner "local-exec" {
    command = "sleep 60"
  }

  provisioner "local-exec" {
    command = "cd '${path.module}/art';./art.sh"
  }

  provisioner "remote-exec" {
    inline = ["whoami"]

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

  provisioner "local-exec" {
    command = "ansible-playbook -i '${path.module}/hosts-${var.endpoint_hostname}.cfg' '${path.module}/playbook.yml'"
  }
  depends_on = [azurerm_windows_virtual_machine.win10]
}
