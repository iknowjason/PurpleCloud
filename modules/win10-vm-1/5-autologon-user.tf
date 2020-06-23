  resource "null_resource" "autologon-users" {
  
  # Wait a solid 5 minuts (300 seconds) for this machine to join the domain
  # Wait this amount of time before the provisioner below starts
    provisioner "local-exec" {
    command = "sleep 300"
   }

    provisioner "remote-exec" {
        inline = ["whoami"]

    connection {
      host     = "${azurerm_public_ip.win10-1-external.ip_address}"
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