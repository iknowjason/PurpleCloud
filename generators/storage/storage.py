# Create a Storage account and some resources!  Writes storage.tf.
# This script helps you to automatically and quickly write terraform
# From there you can customize your terraform further and create your own templates!
# Author:  Jason Ostrom
import os.path
import argparse

# argparser stuff
parser = argparse.ArgumentParser(description='A script to create an Azure storage account and other resources')

# Add argument for name for the name for resource group, storage account, and key vault 
parser.add_argument('-n', '--name', dest='name')

# Add argument for location
parser.add_argument('-l', '--location', dest='location')

# parse arguments
args = parser.parse_args()

# Azure Storage terraform file
tstorage_file = "storage.tf"

# providers terraform file
tproviders_file = "providers.tf"

# parse the name if specified
# it will be used for resource group, key vault, and storage account
default_name = "purplestorage${random_string.ssuffix.id}"
if not args.name:
    print("[+] Using default name: ", default_name)
else:
    default_name = args.name
    print("[+] Using name for resources: ", default_name)

# parse the Azure location if specified
supported_azure_locations = ['westus', 'westus2', 'eastus', 'centralus', 'centraluseuap', 'southcentralus' , 'northcentralus', 'westcentralus', 'eastus2', 'eastus2euap', 'brazilsouth', 'brazilus', 'northeurope', 'westeurope', 'eastasia', 'southeastasia', 'japanwest', 'japaneast', 'koreacentral', 'koreasouth', 'southindia', 'westindia', 'centralindia', 'australiaeast', 'australiasoutheast', 'canadacentral', 'canadaeast', 'uksouth', 'ukwest', 'francecentral', 'francesouth', 'australiacentral', 'australiacentral2', 'uaecentral', 'uaenorth', 'southafricanorth', 'southafricawest', 'switzerlandnorth', 'switzerlandwest', 'germanynorth', 'germanywestcentral', 'norwayeast', 'norwaywest', 'brazilsoutheast', 'westus3', 'swedencentral', 'swedensouth'
]

default_location = "centralus"
if not args.location:
    print("[+] Using default location: ", default_location)
    #logging.info('[+] Using default location: %s', default_location)
else:
    default_location = args.location
    if default_location in supported_azure_locations:
        # this is a supported Azure location
        print("[+] Using Azure location: ", default_location)
        #logging.info('[+] Using Azure location: %s', default_location)
    else:
        print("[-] This is not a supported azure location: ",default_location)
        print("[-] Check the supported_azure_locations if you need to add a new official Azure location")
        exit()

#####
# Functions
#####

# Get the azure storage terraform template
def get_storage_template():
    template = '''

# Random string for resources
resource "random_string" "ssuffix" {
  length  = 5
  special = false
  upper   = false
}

resource "random_password" "secret1" {
  length           = 16
  special          = false
}

resource "random_password" "secret2" {
  length           = 16
  special          = false
}

resource "random_password" "secret3" {
  length           = 16
  special          = false
}

locals {
  # The friendly name for the resource group, storage account, and key vault
  # if this is not specified at the command line the default will be randomly generated
  pstorage_friendly_name = "PURPLECLOUD-FRIENDLY"

  # access type: blob
  pstorage_container1   = "container1"

  # access type: container
  pstorage_container2   = "container2"

  # access type: private
  pstorage_container3   = "container3"
}

variable "storage_location" {
  default = "STORAGE_LOCATION"
}

variable "cc_csv" {
  default = "cc.csv"
}

variable "customers_csv" {
  default = "customers.csv"
}

variable "finance_xlsx" {
  default = "finance.xlsx"
}

variable "hr_xlsx" {
  default = "hr.xlsx"
}

variable "key_name" {
  default = "private-key1"
}

variable "certificate_name" {
  default = "certificate1"
}

variable "hr_share" {
  default = "human-resources"
}

variable "finance_share" {
  default = "finance"
}

variable "hr_file1" {
  default = "employees.xlsx"
}

variable "finance_file1" {
  default = "2022-yearend-projections.xlsx"
}

variable "secret1_name" {
  default = "local-admin"
}

variable "secret2_name" {
  default = "root"
}

variable "secret3_name" {
  default = "developer-service"
}

# Resource group for purplecloud storage lab
resource "azurerm_resource_group" "pc_storage" {
  name     = local.pstorage_friendly_name
  location = var.storage_location
}

# Create the storage account
resource "azurerm_storage_account" "pc_storage" {
  name                     = local.pstorage_friendly_name
  resource_group_name      = azurerm_resource_group.pc_storage.name
  location                 = azurerm_resource_group.pc_storage.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_nested_items_to_be_public = true

  depends_on = [azurerm_resource_group.pc_storage]

  tags = {
    environment = "purplecloud-storage"
  }
}

# Create storage container1 with access type of 'blob'
resource "azurerm_storage_container" "pstorage_container1" {
  name                  = local.pstorage_container1
  storage_account_name  = azurerm_storage_account.pc_storage.name 
  container_access_type = "blob"

  depends_on = [
    azurerm_resource_group.pc_storage,
    azurerm_storage_account.pc_storage
  ]
}

# Create storage container2 with access type of 'container'
resource "azurerm_storage_container" "pstorage_container2" {
  name                  = local.pstorage_container2
  storage_account_name  = azurerm_storage_account.pc_storage.name 
  container_access_type = "container"

  depends_on = [
    azurerm_resource_group.pc_storage,
    azurerm_storage_account.pc_storage
  ]
}

# Create storage container3 with access type of 'private'
resource "azurerm_storage_container" "pstorage_container3" {
  name                  = local.pstorage_container3
  storage_account_name  = azurerm_storage_account.pc_storage.name 
  container_access_type = "private"

  depends_on = [
    azurerm_resource_group.pc_storage,
    azurerm_storage_account.pc_storage
  ]
}

# Load cc.csv data in all three containers
resource "azurerm_storage_blob" "cc1_csv" {
  name                   = var.cc_csv
  storage_account_name   = azurerm_storage_account.pc_storage.name
  storage_container_name = azurerm_storage_container.pstorage_container1.name
  type                   = "Block"
  source                 = "${path.module}/data/cc.csv"
}

resource "azurerm_storage_blob" "cc2_csv" {
  name                   = var.cc_csv
  storage_account_name   = azurerm_storage_account.pc_storage.name
  storage_container_name = azurerm_storage_container.pstorage_container2.name
  type                   = "Block"
  source                 = "${path.module}/data/cc.csv"
}

resource "azurerm_storage_blob" "cc3_csv" {
  name                   = var.cc_csv
  storage_account_name   = azurerm_storage_account.pc_storage.name
  storage_container_name = azurerm_storage_container.pstorage_container3.name
  type                   = "Block"
  source                 = "${path.module}/data/cc.csv"
}

# Load customers.csv data in all three containers
resource "azurerm_storage_blob" "customer1_csv" {
  name                   = var.customers_csv
  storage_account_name   = azurerm_storage_account.pc_storage.name
  storage_container_name = azurerm_storage_container.pstorage_container1.name
  type                   = "Block"
  source                 = "${path.module}/data/customers.csv"
}

resource "azurerm_storage_blob" "customer2_csv" {
  name                   = var.customers_csv
  storage_account_name   = azurerm_storage_account.pc_storage.name
  storage_container_name = azurerm_storage_container.pstorage_container2.name
  type                   = "Block"
  source                 = "${path.module}/data/customers.csv"
}

resource "azurerm_storage_blob" "customer3_csv" {
  name                   = var.customers_csv
  storage_account_name   = azurerm_storage_account.pc_storage.name
  storage_container_name = azurerm_storage_container.pstorage_container3.name
  type                   = "Block"
  source                 = "${path.module}/data/customers.csv"
}

# Load finance.xlsx data in all three containers
resource "azurerm_storage_blob" "finance1_xlsx" {
  name                   = var.finance_xlsx
  storage_account_name   = azurerm_storage_account.pc_storage.name
  storage_container_name = azurerm_storage_container.pstorage_container1.name
  type                   = "Block"
  source                 = "${path.module}/data/finance.xlsx"
}

resource "azurerm_storage_blob" "finance2_xlsx" {
  name                   = var.finance_xlsx
  storage_account_name   = azurerm_storage_account.pc_storage.name
  storage_container_name = azurerm_storage_container.pstorage_container2.name
  type                   = "Block"
  source                 = "${path.module}/data/finance.xlsx"
}

resource "azurerm_storage_blob" "finance3_xlsx" {
  name                   = var.finance_xlsx
  storage_account_name   = azurerm_storage_account.pc_storage.name
  storage_container_name = azurerm_storage_container.pstorage_container3.name
  type                   = "Block"
  source                 = "${path.module}/data/finance.xlsx"
}

# Load hr.xlsx data in all three containers
resource "azurerm_storage_blob" "hr1_xlsx" {
  name                   = var.hr_xlsx
  storage_account_name   = azurerm_storage_account.pc_storage.name
  storage_container_name = azurerm_storage_container.pstorage_container1.name
  type                   = "Block"
  source                 = "${path.module}/data/hr.xlsx"
}

resource "azurerm_storage_blob" "hr2_xlsx" {
  name                   = var.hr_xlsx
  storage_account_name   = azurerm_storage_account.pc_storage.name
  storage_container_name = azurerm_storage_container.pstorage_container2.name
  type                   = "Block"
  source                 = "${path.module}/data/hr.xlsx"
}

resource "azurerm_storage_blob" "hr3_xlsx" {
  name                   = var.hr_xlsx
  storage_account_name   = azurerm_storage_account.pc_storage.name
  storage_container_name = azurerm_storage_container.pstorage_container3.name
  type                   = "Block"
  source                 = "${path.module}/data/hr.xlsx"
}

# Azure files share name - HR
resource "azurerm_storage_share" "pc_hr" {
  name                 = var.hr_share
  storage_account_name = azurerm_storage_account.pc_storage.name
  quota                = 50
}

# Azure files share name - Finance
resource "azurerm_storage_share" "pc_finance" {
  name                 = var.finance_share
  storage_account_name = azurerm_storage_account.pc_storage.name
  quota                = 50
}

# Sample HR file
resource "azurerm_storage_share_file" "hr1" {
  name             = var.hr_file1
  storage_share_id = azurerm_storage_share.pc_hr.id
  source           = "${path.module}/data/hr.xlsx"
}

# Sample Finance file
resource "azurerm_storage_share_file" "finance1" {
  name             = var.finance_file1
  storage_share_id = azurerm_storage_share.pc_finance.id
  source           = "${path.module}/data/finance.xlsx"
}

# Azure Keyvault
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "purplecloud" {
  name                       = local.pstorage_friendly_name
  location                   = azurerm_resource_group.pc_storage.location
  resource_group_name        = azurerm_resource_group.pc_storage.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "premium"
  soft_delete_retention_days = 7

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    certificate_permissions = [
      "Create",
      "Delete",
      "DeleteIssuers",
      "Get",
      "GetIssuers",
      "Import",
      "List",
      "ListIssuers",
      "ManageContacts",
      "ManageIssuers",
      "Purge",
      "SetIssuers",
      "Update",
    ]

    key_permissions = [
      "Backup",
      "Create",
      "Decrypt",
      "Delete",
      "Encrypt",
      "Get",
      "Import",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Sign",
      "UnwrapKey",
      "Update",
      "Verify",
      "WrapKey",
    ]

    secret_permissions = [
      "Backup",
      "Delete",
      "Get",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Set",
    ]
  }
}

resource "azurerm_key_vault_secret" "secret1" {
  name         = var.secret1_name
  value        = random_password.secret1.result
  key_vault_id = azurerm_key_vault.purplecloud.id
}

resource "azurerm_key_vault_secret" "secret2" {
  name         = "root"
  value        = random_password.secret2.result
  key_vault_id = azurerm_key_vault.purplecloud.id
}

resource "azurerm_key_vault_secret" "secret3" {
  name         = var.secret3_name
  value        = random_password.secret3.result
  key_vault_id = azurerm_key_vault.purplecloud.id
}

resource "azurerm_key_vault_key" "purplecloud_generated" {
  name         = var.key_name
  key_vault_id = azurerm_key_vault.purplecloud.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}

resource "azurerm_key_vault_certificate" "purplecloud" {
  name         = var.certificate_name
  key_vault_id = azurerm_key_vault.purplecloud.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      # Server Authentication = 1.3.6.1.5.5.7.3.1
      # Client Authentication = 1.3.6.1.5.5.7.3.2
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject_alternative_names {
        dns_names = ["internal.contoso.com", "domain.hello.world"]
      }
      subject            = "CN=hello-world"
      validity_in_months = 12
    }
  }
}

output "storage_key_vault_details" {
  value = <<EOS

-----------------------
Storage Account Setup Complete
-----------------------
Resource Group: ${azurerm_resource_group.pc_storage.name}
Location: ${azurerm_resource_group.pc_storage.location}
Storage Account: ${azurerm_storage_account.pc_storage.name}

----------
Containers
----------
Name: ${azurerm_storage_container.pstorage_container1.name}
Access type: ${azurerm_storage_container.pstorage_container1.container_access_type}
URL:  https://${azurerm_storage_account.pc_storage.name}.blob.core.windows.net/${azurerm_storage_container.pstorage_container1.name}

Name: ${azurerm_storage_container.pstorage_container2.name}
Access type: ${azurerm_storage_container.pstorage_container2.container_access_type}
URL:  https://${azurerm_storage_account.pc_storage.name}.blob.core.windows.net/${azurerm_storage_container.pstorage_container2.name}

Name: ${azurerm_storage_container.pstorage_container3.name}
Access type: ${azurerm_storage_container.pstorage_container3.container_access_type}
URL:  https://${azurerm_storage_account.pc_storage.name}.blob.core.windows.net/${azurerm_storage_container.pstorage_container3.name}

-------
Blobs:
-------
${azurerm_storage_blob.cc1_csv.name}
${azurerm_storage_blob.customer1_csv.name}
${azurerm_storage_blob.finance1_xlsx.name}
${azurerm_storage_blob.hr1_xlsx.name}

-----
Azure File Shares
-----
Share URL:  https://${azurerm_storage_account.pc_storage.name}.file.core.windows.net/${azurerm_storage_share.pc_finance.name}
File  URL:  https://${azurerm_storage_account.pc_storage.name}.file.core.windows.net/${azurerm_storage_share.pc_finance.name}/${azurerm_storage_share_file.finance1.name}

Share URL:  https://${azurerm_storage_account.pc_storage.name}.file.core.windows.net/${azurerm_storage_share.pc_hr.name}
File  URL:  https://${azurerm_storage_account.pc_storage.name}.file.core.windows.net/${azurerm_storage_share.pc_hr.name}/${azurerm_storage_share_file.hr1.name}

---------
Key Vault
---------
Name: ${azurerm_key_vault.purplecloud.name}

----
Key Vault Secrets
----
Name: ${azurerm_key_vault_secret.secret1.name}
Name: ${azurerm_key_vault_secret.secret2.name}
Name: ${azurerm_key_vault_secret.secret3.name}

----
Key Vault Keys
----
Name: ${azurerm_key_vault_key.purplecloud_generated.name}

----
Key Vault Certificates
----
Name: ${azurerm_key_vault_certificate.purplecloud.name}

EOS
}
'''
    return template
# End of storage terraform template

def get_providers_template():
    template = '''

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=3.13.0"
    }
  }
}

provider "azurerm" {
  features {}
}

'''
    return template
# End of providers template

# Write the providers.tf if needed
if os.path.exists(tproviders_file):
    print("[+] The providers.tf file already exists: ",tproviders_file)
else:
    providers_text_file = open(tproviders_file, "w")
    # Get the providers.tf template
    providers_template = get_providers_template()
    n = providers_text_file.write(providers_template)
    print("[+] Creating the providers terraform file: ",tproviders_file)
    #logging.info('[+] Creating the providers terraform file: %s', tproviders_file)
    providers_text_file.close()

# Write the storage.tf file 
storage_text_file = open(tstorage_file, "w")

# Get the storage.tf template
default_storage_template = get_storage_template()

# replace the location variable
storage_template = default_storage_template.replace("STORAGE_LOCATION",default_location) 

# replace the name variable
storage_template = storage_template.replace("PURPLECLOUD-FRIENDLY",default_name) 

# write the file
n = storage_text_file.write(storage_template)

# print
print("[+] Creating the storage terraform file: ",tstorage_file)

# close the file
storage_text_file.close()
