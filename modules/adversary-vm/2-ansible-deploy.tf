resource "null_resource" "ansible-deploy" {

  provisioner "remote-exec" {
    inline = ["echo 'Hello World'"]

    connection {
      host        = azurerm_public_ip.myterraformpublicip.ip_address
      type        = "ssh"
      user        = "aria"
      private_key = tls_private_key.example_ssh.private_key_pem
      timeout     = "3m"
    }
  }
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${path.module}/hosts.cfg' --private-key ${path.module}/ssh_key.pem '${path.module}/playbook.yml'"
  }
  depends_on = [azurerm_linux_virtual_machine.myterraformvm]
}
