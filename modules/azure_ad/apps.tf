# Create HR application
resource "azuread_application" "HR_Application" {
  display_name = "${var.tenant_id} HR-App"
}

# Create HR service principal 
resource "azuread_service_principal" "SP_HR_App" {
  application_id = azuread_application.HR_Application.application_id

 depends_on = [azuread_application.HR_Application]
}

# Create Finance application
resource "azuread_application" "Finance_Application" {
  display_name = "${var.tenant_id} Fin-App"
}

# Create Finance service principal 
resource "azuread_service_principal" "SP_Fin_App" {
  application_id = azuread_application.Finance_Application.application_id

 depends_on = [azuread_application.Finance_Application]
}
