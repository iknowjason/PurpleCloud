  resource "null_resource" "provision-dc-users" {
  
    provisioner "remote-exec" {
        inline = ["whoami"]

    connection {
      host     = "${azurerm_public_ip.dc1-external.ip_address}"
      type     = "winrm"
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      timeout  = "15m"
      https    = true
      port     = "5986"
      insecure = true
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i '${path.module}/hosts.cfg' '${path.module}/playbook.yml'"
  }

    depends_on = ["null_resource.wait-for-domain-to-provision"]
  }
