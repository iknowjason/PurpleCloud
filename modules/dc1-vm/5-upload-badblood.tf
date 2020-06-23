resource "null_resource" "upload-badblood" {

  provisioner "file" {
    source      = "${path.module}/files/badblood.zip"
    destination = "C:/terraform/badblood.zip"
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

  depends_on = ["null_resource.wait-for-domain-to-provision"]
}