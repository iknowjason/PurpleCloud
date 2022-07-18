# Create an Azure Sentinel deployment!  Writes sentinel.tf.
# This script helps you to automatically and quickly write terraform
# From there you can customize your terraform further and create your own templates!
# Author:  Jason Ostrom
import os.path
import argparse

# argparser stuff
parser = argparse.ArgumentParser(description='A script to create terraform for an Azure Sentinel lab')

# Add argument for name for resource group and log analytics workspace
parser.add_argument('-n', '--name', dest='name')

# Add argument for location
parser.add_argument('-l', '--location', dest='location')

# Add argument for enabling Office 365 data connector 
parser.add_argument('-odc', '--data_connector_office', dest='odc_enable', action='store_true')

# Add argument for enabling Azure AD logs data connector 
parser.add_argument('-adc', '--data_connector_aad', dest='adc_enable', action='store_true')

# parse arguments
args = parser.parse_args()

# Azure Sentinel terraform file
tsentinel_file = "sentinel.tf"

# providers terraform file
tproviders_file = "providers.tf"

# parse the name if specified
default_name = "purplecloud-sentinel"
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

## Check if office 365 data connector is enabled 
if args.odc_enable:
    print("[+] Office 365 data connector will be enabled for Sentinel")

## Check if Azure AD data connector is enabled 
if args.adc_enable:
    print("[+] Azure AD data connector will be enabled for Sentinel")

#####
# Functions
#####

# Get the azure sentinel terraform template
def get_sentinel_template():
    template = '''

variable "sentinel_name" {
  default = "SENTINEL_NAME"
}

variable "sentinel_location" {
  default = "SENTINEL_LOCATION"
}

resource "azurerm_resource_group" "pc" {
  name     = var.sentinel_name 
  location = var.sentinel_location 
}

resource "azurerm_log_analytics_workspace" "pc" {
  name                = var.sentinel_name 
  location            = var.sentinel_location 
  resource_group_name = "${azurerm_resource_group.pc.name}"
  sku                 = "PerGB2018"
  retention_in_days   = 90
}

resource "azurerm_log_analytics_solution" "pc" {
  solution_name         = "SecurityInsights"
  location              = var.sentinel_location 
  resource_group_name   = "${azurerm_resource_group.pc.name}"
  workspace_resource_id = "${azurerm_log_analytics_workspace.pc.id}"
  workspace_name        = "${azurerm_log_analytics_workspace.pc.name}"
  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/SecurityInsights"
  }
}
output "sentinel_details" {
  value = <<EOS

Azure Sentinel Details
-----------------------
Resource Group: ${azurerm_resource_group.pc.name}
Location: ${azurerm_resource_group.pc.location}
Log Analytics Workspace: ${azurerm_log_analytics_workspace.pc.name}
Log Analytics Solution: ${azurerm_log_analytics_solution.pc.solution_name}
-----------------------


EOS
}
AAD_DATA_CONNECTOR
O365_DATA_CONNECTOR
'''
    return template
# End of sentinel terraform template

# Template for office_365 data connector
template_o365_dc = '''
resource "azurerm_sentinel_data_connector_office_365" "example" {
  name                       = "example"
  log_analytics_workspace_id = azurerm_log_analytics_solution.pc.workspace_resource_id
  exchange_enabled           = true
  sharepoint_enabled         = true
  teams_enabled              = true
}
''' 

# Template for Azure AD data connector
template_aad_dc = '''
resource "azurerm_sentinel_data_connector_azure_active_directory" "pc" {
  name                       = "pc-ad-connector"
  log_analytics_workspace_id = azurerm_log_analytics_solution.pc.workspace_resource_id
}
''' 

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

# Write the sentinel.tf file 
sentinel_text_file = open(tsentinel_file, "w")

# Get the sentinel.tf template
default_sentinel_template = get_sentinel_template()

# replace the location variable
sentinel_template = default_sentinel_template.replace("SENTINEL_LOCATION",default_location) 

# replace the name variable
sentinel_template = sentinel_template.replace("SENTINEL_NAME",default_name) 

# replace the optional o365 data connector if specified 
if args.odc_enable:
    sentinel_template = sentinel_template.replace("O365_DATA_CONNECTOR",template_o365_dc) 
else:
    sentinel_template = sentinel_template.replace("O365_DATA_CONNECTOR","") 

# replace the optional Azure AD data connector if specified 
if args.adc_enable:
    sentinel_template = sentinel_template.replace("AAD_DATA_CONNECTOR",template_aad_dc) 
else:
    sentinel_template = sentinel_template.replace("AAD_DATA_CONNECTOR","") 

# write the file
n = sentinel_text_file.write(sentinel_template)

# print
print("[+] Creating the sentinel terraform file: ",tsentinel_file)

# close the file
sentinel_text_file.close()
