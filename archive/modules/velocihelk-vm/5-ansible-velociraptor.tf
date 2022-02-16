  resource "null_resource" "ansible-velociraptor-implementation" {
  
    provisioner "remote-exec" {
        inline = ["echo 'Hello World'"]

    connection {
      host     = azurerm_public_ip.vh-external.ip_address
      type     = "ssh"
      user     = "helk"
      private_key = tls_private_key.example_ssh.private_key_pem
      timeout  = "3m"
    }
  }
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${path.module}/hosts.cfg' --private-key '${path.module}/ssh_key.pem' '${path.module}/playbook-velociraptor.yml'"
  }

  ## config file download after adding client parameter for trusting self-signed cert
  ## this is necessary for current convenience
  provisioner "local-exec" {
    command = "scp -i ${path.module}/ssh_key.pem helk@${azurerm_public_ip.vh-external.ip_address}:/home/helk/server.config.yaml ${path.module}/files/config.yaml"
  }

    depends_on = [null_resource.velociraptor-config]

  }
