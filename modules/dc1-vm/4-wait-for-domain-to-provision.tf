# Wait 13 minutes (780 seconds) for the domain / active direcotry forest to provision
# from my measurements this normally takes 11 minutes
resource "null_resource" "wait-for-domain-to-provision" {
  provisioner "local-exec" {
    command = "sleep 780"
  }
  depends_on = ["azurerm_virtual_machine.domain-controller"]
}
