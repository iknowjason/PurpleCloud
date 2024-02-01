# Create an Azure Managed Identity security lab!  Writes managed_identity.tf.
# This script helps you to automatically and quickly write terraform
# From there you can customize your terraform further and create your own templates!
# Author:  Jason Ostrom
import os.path
import argparse
from faker import Faker

# argparser stuff
parser = argparse.ArgumentParser(description='A script to create an Azure Managed Identity security lab')

# Add argument for name for resource group and other named variables
parser.add_argument('-n', '--name', dest='name')

# Add argument for location
parser.add_argument('-l', '--location', dest='location')

# Add argument for  Local Administrator
parser.add_argument('-a', '--admin', dest='admin_set')

# Add argument for password
parser.add_argument('-p', '--password', dest='password_set')

# Add argument enabling a system-assigned Identity (Default:  Not Enabled)
parser.add_argument('-sa', '--system_identity', dest='system_assigned_identity', action='store_true') 

# Add argument enabling a User Assigned Identity (Default:  Reader)
# This can be set to Reader, Contributor, or Owner 
parser.add_argument('-ua', '--user_identity', dest='user_assigned_identity')

# Add argument for upn_suffix
parser.add_argument('-u', '--upn', dest='upn_suffix')

# parse arguments
args = parser.parse_args()

# Azure managed identity terraform file
tmi_file = "managed_identity.tf"

# Azure AD user in this file
tuser_file = "mi_user.tf"

# providers terraform file
tproviders_file = "providers.tf"

# The identity type for the VM managed identity assignment
# Default is UserAssigned with Reader
identity_type = "UserAssigned"

# Check if system assigned identity is used
if args.system_assigned_identity:
    print("[+] System Assigned Identity will be used")
    identity_type = "SystemAssigned"

if args.user_assigned_identity:
    identity = args.user_assigned_identity
    if identity.lower() == 'reader':
        print("[+] User Assigned Identity with Reader role enabled")
    elif identity.lower() == 'contributor':
        print("[+] User Assigned Identity with Contributor role enabled")
    elif identity.lower() == 'owner':
        print("[+] User Assigned Identity with Owner role enabled")
    else:
        print("[-] The user assigned identity value must be either reader, contributor, or owner")
        print(    "[-] Example:  python3 managed_identity.py -u acme.io --user_identity reader")
        print("    [-] Example:  python3 managed_identity.py -u acme.io --user_identity contributor")
        print("    [-] Example:  python3 managed_identity.py -u acme.io --user_identity owner")
        exit(1)


# the Identity Type string for SystemAssigned, UserAssigned, or both
if args.system_assigned_identity and args.user_assigned_identity:
    print("[+] Identity Type is SystemAssigned, UserAssigned")
    identity_type = "SystemAssigned, UserAssigned"

if not args.upn_suffix:
    print("[-] No upn_suffix specified")
    print("    [-] A upn (User Principal Name) Suffix must be specified in order to create a user")
    print("    [-] Suffix can be a custom domain name you have added to Azure")
    print("    [-] Or the default, which is your tenant username + .onmicrosoft.com")
    print("    [-] Example with custom domain:")
    print("    [-] % python3 managed_identity.py -u acme.io")
    print("    [-] Example with default tenant username + onmicrosoft.com:")
    print("    [-] % python3 managed_identity.py -u acme.onmicrosoft.com")
    exit()
else:
    pass

# get Local Admin
default_admin_username = "MIAdmin"
default_input_admin = ""
if args.admin_set:
    default_input_admin = args.admin_set
    print("[+] Local Admin account name for Windows: ",default_input_admin)
else:
    print("[+] Using Default Local Admin account name for Windows: ",default_admin_username)

# get input password
default_input_password = ""
if args.password_set:
    default_input_password = args.password_set
    print("[+] Password desired for Azure AD user and Windows 10 local admin: ",default_input_password)
else:
    print("[+] No password specified on command line ~ Defaulting to auto-generated")

# parse the name if specified
default_name = "purpleidentity${random_string.misuffix.id}"
if not args.name:
    print("[+] Using default name for Resource Group and other variables (--name)")
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
    else:
        print("[-] This is not a supported azure location: ",default_location)
        print("[-] Check the supported_azure_locations if you need to add a new official Azure location")
        exit()

#####
# Functions
#####

# Get the azure managed identity terraform template
def get_mi_template():
    template = '''

# managed_identity.tf:  This file contains resources for a managed identity security lab

# LOCALS - Place all locals here if you can
locals {
  # The friendly name for the resource group, storage account, and key vault
  # if this is not specified at the command line the default will be randomly generated
  mi_friendly_name = "PURPLECLOUD-FRIENDLY"
  vnet_name_mi = "PURPLECLOUD-FRIENDLY"
  mi_nsg_name = "PURPLECLOUD-FRIENDLY"
  micreds        = "MICREDS" 
  micomputername = "win10-mi"

  # access type: blob
  mi_container1   = "container1"

  # access type: container
  mi_container2   = "container2"

  # access type: private
  mi_container3   = "container3"
}

###
# VARIABLES
###
# the address space for the mi vnet
variable "vnetmi_address_space" {
  default = ["10.101.0.0/16"]
}
variable "vm_subnet_name" {
  default = "managed_identity_lab"
}
variable "vm_subnet_prefix" {
  default = "10.101.10.0/24"
}
variable "internal_dns_name" {
  default = "win10-mi"
}
variable "mi_private_nic_ip" {
  default = "10.101.10.10"
}

# Thanks to @christophetd and his Github.com/Adaz project for this little code
data "http" "firewall_allowed" {
  url = "http://ifconfig.so"
}

# This is the src_ip for white listing Azure NSGs
locals {
  src_ip = chomp(data.http.firewall_allowed.response_body)
  #src_ip = "0.0.0.0/0" 
}

variable "mi_admin_username" {
  default = "MIADMIN_DEFAULT"
}
variable "mi_location" {
  default = "MI_LOCATION"
}
variable "identity_type" {
  default = "IDENTITY_TYPE"
}
variable "identity_name" {
  default = "uaidentity"
}
resource "random_password" "secret1_mi" {
  length           = 16
  special          = false
}
resource "random_password" "secret2_mi" {
  length           = 16
  special          = false
}
resource "random_password" "secret3_mi" {
  length           = 16
  special          = false
}
variable "secret1_name_mi" {
  default = "local-admin"
}
variable "secret2_name_mi" {
  default = "root"
}
variable "secret3_name_mi" {
  default = "developer-service"
}
variable "key_name_mi" {
  default = "private-key1"
}
variable "certificate_name_mi" {
  default = "certificate1"
}
variable "mi_cc_csv" {
  default = "cc.csv"
}
variable "mi_customers_csv" {
  default = "customers.csv"
}
variable "mi_finance_xlsx" {
  default = "finance.xlsx"
}
variable "mi_hr_xlsx" {
  default = "hr.xlsx"
}
variable "mi_hr_share" {
  default = "human-resources"
}
variable "mi_finance_share" {
  default = "finance"
}
variable "mi_hr_file1" {
  default = "employees.xlsx"
}
variable "mi_finance_file1" {
  default = "2022-yearend-projections.xlsx"
}
###
# RESOURCES
###
# Random string for resources
resource "random_string" "misuffix" {
  length  = 5
  special = false
  upper   = false
}
# Random Pet for user password (First part of password)
resource "random_pet" "mi_rp_string" {
  length = 2
}
# Random String for password (Second part of password)
resource "random_string" "mi_password" {
  length  = 4
  special = false
  upper   = true
}

# Resource group for managed identity lab
resource "azurerm_resource_group" "pcmi" {
  name     = local.mi_friendly_name
  location = var.mi_location
}

# Create the User Assigned Managed Identity
resource "azurerm_user_assigned_identity" "uai" {
  resource_group_name = azurerm_resource_group.pcmi.name 
  location            = var.mi_location
  name                = var.identity_name 
}

# Assign the reader role on the Key vault to the Managed Identity
resource "azurerm_role_assignment" "uai" {
  #Scope to the key vault in line below
  #scope                = azurerm_key_vault.example.id
  #Scope to the subscription in line below 
  scope                = data.azurerm_subscription.mi.id
  role_definition_name = "ROLE_DEFINITION_NAME"
  principal_id         = azurerm_user_assigned_identity.uai.principal_id
}

resource "azurerm_key_vault_access_policy" "uai" {
  key_vault_id = azurerm_key_vault.purplecloud_mi.id
  tenant_id    = data.azurerm_client_config.mi.tenant_id
  object_id    = azurerm_user_assigned_identity.uai.principal_id

  key_permissions = [
    "Get","List",
  ]

  secret_permissions = [
    "Get","List",
  ]
}

resource "azurerm_key_vault" "purplecloud_mi" {
  name                       = local.mi_friendly_name 
  location                   = azurerm_resource_group.pcmi.location
  resource_group_name        = azurerm_resource_group.pcmi.name 
  tenant_id                  = data.azurerm_client_config.mi.tenant_id
  sku_name                   = "premium"
  soft_delete_retention_days = 7

  access_policy {
    tenant_id = data.azurerm_client_config.mi.tenant_id
    object_id = data.azurerm_client_config.mi.object_id

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

resource "azurerm_key_vault_secret" "secret1_mi" {
  name         = var.secret1_name_mi
  value        = random_password.secret1_mi.result
  key_vault_id = azurerm_key_vault.purplecloud_mi.id
}

resource "azurerm_key_vault_secret" "secret2_mi" {
  name         = var.secret2_name_mi
  value        = random_password.secret2_mi.result
  key_vault_id = azurerm_key_vault.purplecloud_mi.id
}

resource "azurerm_key_vault_secret" "secret3_mi" {
  name         = var.secret3_name_mi
  value        = random_password.secret3_mi.result
  key_vault_id = azurerm_key_vault.purplecloud_mi.id
}

resource "azurerm_key_vault_key" "purplecloud_mi" {
  name         = var.key_name_mi
  key_vault_id = azurerm_key_vault.purplecloud_mi.id
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

resource "azurerm_key_vault_certificate" "purplecloud_mi" {
  name         = var.certificate_name_mi
  key_vault_id = azurerm_key_vault.purplecloud_mi.id

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

# Create the storage account
resource "azurerm_storage_account" "mi_storage" {
  name                     = local.mi_friendly_name
  resource_group_name      = azurerm_resource_group.pcmi.name
  location                 = azurerm_resource_group.pcmi.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_nested_items_to_be_public = true

  depends_on = [azurerm_resource_group.pcmi]

  tags = {
    environment = "purplecloud-managed-identity-storage"
  }
}

# Create storage container1 with access type of 'blob'
resource "azurerm_storage_container" "mi_container1" {
  name                  = local.mi_container1
  storage_account_name  = azurerm_storage_account.mi_storage.name
  container_access_type = "blob"

  depends_on = [
    azurerm_resource_group.pcmi,
    azurerm_storage_account.mi_storage
  ]
}

# Create storage container2 with access type of 'container'
resource "azurerm_storage_container" "mi_container2" {
  name                  = local.mi_container2
  storage_account_name  = azurerm_storage_account.mi_storage.name
  container_access_type = "container"

  depends_on = [
    azurerm_resource_group.pcmi,
    azurerm_storage_account.mi_storage
  ]
}

# Create storage container3 with access type of 'private'
resource "azurerm_storage_container" "mi_container3" {
  name                  = local.mi_container3
  storage_account_name  = azurerm_storage_account.mi_storage.name
  container_access_type = "private"

  depends_on = [
    azurerm_resource_group.pcmi,
    azurerm_storage_account.mi_storage
  ]
}

# Load cc.csv data in all three containers
resource "azurerm_storage_blob" "mi_cc1_csv" {
  name                   = var.mi_cc_csv
  storage_account_name   = azurerm_storage_account.mi_storage.name
  storage_container_name = azurerm_storage_container.mi_container1.name
  type                   = "Block"
  source                 = "${path.module}/data/cc.csv"
}

resource "azurerm_storage_blob" "mi_cc2_csv" {
  name                   = var.mi_cc_csv
  storage_account_name   = azurerm_storage_account.mi_storage.name
  storage_container_name = azurerm_storage_container.mi_container2.name
  type                   = "Block"
  source                 = "${path.module}/data/cc.csv"
}

resource "azurerm_storage_blob" "mi_cc3_csv" {
  name                   = var.mi_cc_csv
  storage_account_name   = azurerm_storage_account.mi_storage.name
  storage_container_name = azurerm_storage_container.mi_container3.name
  type                   = "Block"
  source                 = "${path.module}/data/cc.csv"
}

# Load customers.csv data in all three containers
resource "azurerm_storage_blob" "mi_customer1_csv" {
  name                   = var.mi_customers_csv
  storage_account_name   = azurerm_storage_account.mi_storage.name
  storage_container_name = azurerm_storage_container.mi_container1.name
  type                   = "Block"
  source                 = "${path.module}/data/customers.csv"
}

resource "azurerm_storage_blob" "mi_customer2_csv" {
  name                   = var.mi_customers_csv
  storage_account_name   = azurerm_storage_account.mi_storage.name
  storage_container_name = azurerm_storage_container.mi_container2.name
  type                   = "Block"
  source                 = "${path.module}/data/customers.csv"
}

resource "azurerm_storage_blob" "mi_customer3_csv" {
  name                   = var.mi_customers_csv
  storage_account_name   = azurerm_storage_account.mi_storage.name
  storage_container_name = azurerm_storage_container.mi_container3.name
  type                   = "Block"
  source                 = "${path.module}/data/customers.csv"
}

# Load finance.xlsx data in all three containers
resource "azurerm_storage_blob" "mi_finance1_xlsx" {
  name                   = var.mi_finance_xlsx
  storage_account_name   = azurerm_storage_account.mi_storage.name
  storage_container_name = azurerm_storage_container.mi_container1.name
  type                   = "Block"
  source                 = "${path.module}/data/finance.xlsx"
}
resource "azurerm_storage_blob" "mi_finance2_xlsx" {
  name                   = var.mi_finance_xlsx
  storage_account_name   = azurerm_storage_account.mi_storage.name
  storage_container_name = azurerm_storage_container.mi_container2.name
  type                   = "Block"
  source                 = "${path.module}/data/finance.xlsx"
}
resource "azurerm_storage_blob" "mi_finance3_xlsx" {
  name                   = var.mi_finance_xlsx
  storage_account_name   = azurerm_storage_account.mi_storage.name
  storage_container_name = azurerm_storage_container.mi_container3.name
  type                   = "Block"
  source                 = "${path.module}/data/finance.xlsx"
}

# Load hr.xlsx data in all three containers
resource "azurerm_storage_blob" "mi_hr1_xlsx" {
  name                   = var.mi_hr_xlsx
  storage_account_name   = azurerm_storage_account.mi_storage.name
  storage_container_name = azurerm_storage_container.mi_container1.name
  type                   = "Block"
  source                 = "${path.module}/data/hr.xlsx"
}
resource "azurerm_storage_blob" "mi_hr2_xlsx" {
  name                   = var.mi_hr_xlsx
  storage_account_name   = azurerm_storage_account.mi_storage.name
  storage_container_name = azurerm_storage_container.mi_container2.name
  type                   = "Block"
  source                 = "${path.module}/data/hr.xlsx"
}
resource "azurerm_storage_blob" "mi_hr3_xlsx" {
  name                   = var.mi_hr_xlsx
  storage_account_name   = azurerm_storage_account.mi_storage.name
  storage_container_name = azurerm_storage_container.mi_container3.name
  type                   = "Block"
  source                 = "${path.module}/data/hr.xlsx"
}
# Azure files share name - HR
resource "azurerm_storage_share" "mi_hr" {
  name                 = var.mi_hr_share
  storage_account_name = azurerm_storage_account.mi_storage.name
  quota                = 50
}

# Azure files share name - Finance
resource "azurerm_storage_share" "mi_finance" {
  name                 = var.mi_finance_share
  storage_account_name = azurerm_storage_account.mi_storage.name
  quota                = 50
}

# Sample HR file
resource "azurerm_storage_share_file" "mi_hr1" {
  name             = var.mi_hr_file1
  storage_share_id = azurerm_storage_share.mi_hr.id
  source           = "${path.module}/data/hr.xlsx"
}

# Sample Finance file
resource "azurerm_storage_share_file" "mi_finance1" {
  name             = var.mi_finance_file1
  storage_share_id = azurerm_storage_share.mi_finance.id
  source           = "${path.module}/data/finance.xlsx"
}

# Create the VNet
resource "azurerm_virtual_network" "managed_identity" {
  name                = local.vnet_name_mi 
  address_space       = var.vnetmi_address_space
  location            = var.mi_location
  resource_group_name = azurerm_resource_group.pcmi.name 

  depends_on = [azurerm_resource_group.pcmi]
}

# Create the managed identity subnet
resource "azurerm_subnet" "managed_identity" {
  name                 = var.vm_subnet_name 
  resource_group_name  = azurerm_resource_group.pcmi.name 
  virtual_network_name = azurerm_virtual_network.managed_identity.name
  address_prefixes       = [var.vm_subnet_prefix]

  depends_on = [
    azurerm_resource_group.pcmi,
    azurerm_virtual_network.managed_identity,
  ]
}

# nsg association
resource "azurerm_subnet_network_security_group_association" "managed_identity" {
  subnet_id            = azurerm_subnet.managed_identity.id
  network_security_group_id = azurerm_network_security_group.managed_identity.id

  depends_on = [
    azurerm_resource_group.pcmi,
    azurerm_virtual_network.managed_identity,
    azurerm_subnet.managed_identity
  ]
}

resource "azurerm_network_security_group" "managed_identity" {
  name                = local.mi_nsg_name 
  location            = var.mi_location
  resource_group_name = azurerm_resource_group.pcmi.name 
  security_rule {
    name                       = "allow-rdp"
    description                = "Allow Remote Desktop"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = local.src_ip
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-winrms"
    description                = "Windows Remote Managment (HTTPS-In)"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5986"
    source_address_prefix      = local.src_ip
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-winrm"
    description                = "Windows Remote Managment (HTTP-In)"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5985"
    source_address_prefix      = local.src_ip
    destination_address_prefix = "*"
  }
  depends_on = [azurerm_resource_group.pcmi]
}

# the Azure VM for this managed identity lab
resource "azurerm_windows_virtual_machine" "managed_identity" {
  name                          = local.mi_friendly_name 
  resource_group_name           = azurerm_resource_group.pcmi.name 
  location                      = var.mi_location
  size                       = "Standard_A1_v2"
  computer_name  = local.micomputername
  admin_username = var.mi_admin_username
  admin_password = local.micreds 
  provision_vm_agent        = true

  identity {
    type         = var.identity_type 
    IDENTITY_IDS
  }

  network_interface_ids         = [
    azurerm_network_interface.managed_identity.id,
  ]

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "win10-22h2-pro-g2"
    version   = "latest"
  }

  os_disk {
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  additional_unattend_content {
      content      = "<AutoLogon><Password><Value>${local.micreds}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.mi_admin_username}</Username></AutoLogon>"
      setting = "AutoLogon"
  }

  additional_unattend_content {
      content      = file("${path.module}/files/win10/FirstLogonCommands.xml")
      setting = "FirstLogonCommands"
  }

  depends_on = [azurerm_network_interface.managed_identity]
}

resource "azurerm_network_interface" "managed_identity" {
  name                = local.mi_friendly_name 
  location            = var.mi_location
  resource_group_name = azurerm_resource_group.pcmi.name 
  internal_dns_name_label = var.internal_dns_name 

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.managed_identity.id
    private_ip_address_allocation = "Static"
    private_ip_address = var.mi_private_nic_ip 
    public_ip_address_id = azurerm_public_ip.managed_identity.id

  }
  depends_on = [azurerm_resource_group.pcmi]
}

resource "azurerm_public_ip" "managed_identity" {
  name                = local.mi_friendly_name  
  location            = var.mi_location
  resource_group_name = azurerm_resource_group.pcmi.name 
  allocation_method   = "Static"

  depends_on = [azurerm_resource_group.pcmi]
}

output "managed_identity_lab_details" {
  value = <<EOS

Managed Identity Lab Details
-----------------------
Resource Group: ${azurerm_resource_group.pcmi.name}
Location: ${azurerm_resource_group.pcmi.location}
-----------------------

---------------
Virtual Machine
---------------
Computer Name:  ${azurerm_windows_virtual_machine.managed_identity.computer_name}
Private IP: ${var.mi_private_nic_ip} 
Public IP:  ${azurerm_public_ip.managed_identity.ip_address}
local Admin:  ${azurerm_windows_virtual_machine.managed_identity.admin_username}
local password: ${local.micreds}
Managed Identity Name:  ${azurerm_user_assigned_identity.uai.name}
Managed Identity Type: ${var.identity_type} 
User Assigned Role: ${azurerm_role_assignment.uai.role_definition_name}

---------------
Azure AD User
---------------
Name: ${azuread_user.miuser1.display_name}
Username: ${azuread_user.miuser1.mail_nickname}
Email: ${azuread_user.miuser1.user_principal_name}
Password: ${local.micreds}
Assigned Role:  ${var.user_role}

---------------
Storage Account: ${azurerm_storage_account.mi_storage.name}
---------------

----------
Containers
----------
Name: ${azurerm_storage_container.mi_container1.name}
Access type: ${azurerm_storage_container.mi_container1.container_access_type}
URL:  https://${azurerm_storage_account.mi_storage.name}.blob.core.windows.net/${azurerm_storage_container.mi_container1.name}

Name: ${azurerm_storage_container.mi_container2.name}
Access type: ${azurerm_storage_container.mi_container2.container_access_type}
URL:  https://${azurerm_storage_account.mi_storage.name}.blob.core.windows.net/${azurerm_storage_container.mi_container2.name}

Name: ${azurerm_storage_container.mi_container3.name}
Access type: ${azurerm_storage_container.mi_container3.container_access_type}
URL:  https://${azurerm_storage_account.mi_storage.name}.blob.core.windows.net/${azurerm_storage_container.mi_container3.name}

-------
Blobs:
-------
${azurerm_storage_blob.mi_cc1_csv.name}
${azurerm_storage_blob.mi_customer1_csv.name}
${azurerm_storage_blob.mi_finance1_xlsx.name}
${azurerm_storage_blob.mi_hr1_xlsx.name}

-----
Azure File Shares
-----
Share URL:  https://${azurerm_storage_account.mi_storage.name}.file.core.windows.net/${azurerm_storage_share.mi_finance.name}
File  URL:  https://${azurerm_storage_account.mi_storage.name}.file.core.windows.net/${azurerm_storage_share.mi_finance.name}/${azurerm_storage_share_file.mi_finance1.name}

Share URL:  https://${azurerm_storage_account.mi_storage.name}.file.core.windows.net/${azurerm_storage_share.mi_hr.name}
File  URL:  https://${azurerm_storage_account.mi_storage.name}.file.core.windows.net/${azurerm_storage_share.mi_hr.name}/${azurerm_storage_share_file.mi_hr1.name}

---------
Key Vault
---------
Name: ${azurerm_key_vault.purplecloud_mi.name}

----
Key Vault Secrets
----
Name: ${azurerm_key_vault_secret.secret1_mi.name}
Name: ${azurerm_key_vault_secret.secret2_mi.name}
Name: ${azurerm_key_vault_secret.secret3_mi.name}

----
Key Vault Keys
----
Name: ${azurerm_key_vault_key.purplecloud_mi.name}

----
Key Vault Certificates
----
Name: ${azurerm_key_vault_certificate.purplecloud_mi.name}


EOS
}
'''
    return template
# End of managed identity terraform template

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

AADPROVIDER

'''
    return template
# End of providers template

azuread_provider = '''
# Configure the Microsoft Azure Active Directory Provider
provider "azuread" {

}
'''

# Write the providers.tf if needed
#if os.path.exists(tproviders_file):
#    print("[+] The providers.tf file already exists: ",tproviders_file)

providers_text_file = open(tproviders_file, "w")
# Get the providers.tf template
providers_template = get_providers_template()

# check to see if users.tf includes the provider azuread
if os.path.exists("users.tf"):
    #check to see if azuread provider exists
    with open('users.tf') as f:
        if 'provider "azuread" {' in f.read():
            print("[-] AzureAD provider already defined in users.tf")
            providers_template = providers_template.replace("AADPROVIDER","")
        else:
            providers_template = providers_template.replace("AADPROVIDER",azuread_provider)
else:
    print("[+] Adding AzureAD provider to providers.tf")
    providers_template = providers_template.replace("AADPROVIDER",azuread_provider)

n = providers_text_file.write(providers_template)
print("[+] Creating the providers terraform file: ",tproviders_file)
providers_text_file.close()

# Write the managed_identity.tf file 
mi_text_file = open(tmi_file, "w")

# Get the managed_identity.tf template
default_mi_template = get_mi_template()

# replace the location variable
mi_template = default_mi_template.replace("MI_LOCATION",default_location) 

# replace the name variable
mi_template = mi_template.replace("PURPLECLOUD-FRIENDLY",default_name) 

# replace the identity type in block 
mi_template = mi_template.replace("IDENTITY_TYPE",identity_type) 
print("[+] Setting identity type for VM to",identity_type)

# replace the identity_ids as required
identity_ids_line = "" 
if identity_type == "SystemAssigned":
    identity_ids_line = "" 
else:
    #It must be 'SystemAssigned, UserAssigned' or 'UserAssigned'
    identity_ids_line = "identity_ids = [azurerm_user_assigned_identity.uai.id]" 
    print("[+] Setting a user assigned identity identity_ids_line")
#Finally, replace
mi_template = mi_template.replace("IDENTITY_IDS",identity_ids_line) 

# replace the identity type in block 
# replace the role definition name for the user assigned identity 
if args.user_assigned_identity:
    identity = args.user_assigned_identity
    if identity.lower() == 'reader':
        mi_template = mi_template.replace("ROLE_DEFINITION_NAME","Reader") 
    elif identity.lower() == 'contributor':
        mi_template = mi_template.replace("ROLE_DEFINITION_NAME","Contributor") 
    elif identity.lower() == 'owner':
        mi_template = mi_template.replace("ROLE_DEFINITION_NAME","Owner") 
else:
    mi_template = mi_template.replace("ROLE_DEFINITION_NAME","Reader") 

# replace the local administrator account if necessary 
if args.admin_set:
    mi_template = mi_template.replace("MIADMIN_DEFAULT", args.admin_set) 
else:
    mi_template = mi_template.replace("MIADMIN_DEFAULT", default_admin_username) 

# replace the password with user supplied if necessary 
if args.password_set:
    mi_template = mi_template.replace("MICREDS", args.password_set)
else: 
    mi_template = mi_template.replace("MICREDS", "${random_pet.mi_rp_string.id}-${random_string.mi_password.id}")

# write the file
n = mi_text_file.write(mi_template)

# print
print("[+] Creating the managed identity terraform file: ",tmi_file)

# close the file
mi_text_file.close()

### Generate the Azure AD user for Contributor role
### Generate a user's name using Faker
print("[+] Creating Azure AD User for Managed Identity lab")
faker = Faker()
first = faker.unique.first_name()
last = faker.unique.last_name()
username = ((first + last).lower())
display_name = first + " " + last
full = username + "@" + args.upn_suffix
print("    [+] upn suffix:", args.upn_suffix)
print("    [+] Name:", display_name)
print("    [+] Username:", username)
print("    [+] Full UPN:", full)

def get_aad_user_template():
    user_template = '''
variable "mi_upn_suffix" {
  default = "MISUFFIX"
}
resource "azuread_user" "miuser1" {
  user_principal_name = "USERNAME@${var.mi_upn_suffix}"
  display_name        = "DISPLAYNAME"
  mail_nickname       = "USERNAME"
  password            = local.micreds
}

data "azurerm_subscription" "mi" {
}

data "azurerm_client_config" "mi" {
}

# The role scoped to subscription for AAD user
# uncomment as needed
variable "user_role" {
  default = "Virtual Machine Contributor"
  #default = "Contributor"
  #default = "Reader"
  #default = "Owner"
}

resource "azurerm_role_assignment" "mi_contributor" {
  scope                = data.azurerm_subscription.mi.id
  role_definition_name = var.user_role 
  principal_id         = azuread_user.miuser1.object_id
}
'''
    return user_template

# Open file for writing
user_text_file = open(tuser_file, "w")

# Get the tf template
default_user_template = get_aad_user_template()

# replace the username
user_template = default_user_template.replace("USERNAME",username)

# replace the display name
user_template = user_template.replace("DISPLAYNAME",display_name)

# replace the suffix 
user_template = user_template.replace("MISUFFIX",args.upn_suffix)

# write the file
n = user_text_file.write(user_template)

# print
print("[+] Creating the AAD user terraform file: ",tuser_file)

# close the file
user_text_file.close()
