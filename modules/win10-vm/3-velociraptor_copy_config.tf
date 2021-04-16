resource "null_resource" "velociraptor-config" {

  ## Run this module is var.install_agent boolean is true
  count = var.install_agent ? 1 : 0
  
  provisioner "local-exec" {
    command = "cp ../modules/velocihelk-vm/files/config.yaml ${path.module}/files/Velociraptor.config.yaml"
  }
  depends_on = [azurerm_windows_virtual_machine.win10]
}
