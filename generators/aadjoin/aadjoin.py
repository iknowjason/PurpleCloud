# Create an Azure AD Join deployment with Azure VMs and AAD users 
# This script helps you to automatically and quickly write terraform
# From there you can customize your terraform further and create your own templates!
# Author:  Jason Ostrom

from faker import Faker
import random
import argparse
import os
import subprocess
import urllib.request
import secrets
import string
import logging
from csv import reader
import os.path
import linecache


# logfile configuration
logging.basicConfig(format='%(asctime)s %(message)s', filename='ranges.log', level=logging.INFO)

# The instance size for each system
size_win10 = "Standard_D2as_v4"

####
# Functions
####



# argparser stuff
parser = argparse.ArgumentParser(description='A script to create Sentinel deployment with optional VMs')

# Add argument for number of Azure AD users
parser.add_argument('-c', '--count', dest='user_count')

# Add argument for upn_suffix
parser.add_argument('-u', '--upn', dest='upn_suffix')

# Add argument for count of Windows 10 Pro endpoints 
parser.add_argument('-e', '--endpoints', dest='endpoints_count')

# Add argument for resource group name 
parser.add_argument('-r', '--resource_group', dest='resource_group')

# Add argument for location 
parser.add_argument('-l', '--location', dest='location')

# Add argument for  Local Administrator 
parser.add_argument('-a', '--admin', dest='admin_set')

# Add argument for password  
parser.add_argument('-p', '--password', dest='password_set')

# Add argument enabling a User Assigned Identity (Default:  Reader)
# This can be set to Reader, Contributor, or Owner
parser.add_argument('-ua', '--user_identity', dest='user_assigned_identity')

# parse arguments
args = parser.parse_args()

# The identity type for the VM managed identity assignment
# Default is SystemAssigned
identity_type = "SystemAssigned"

# the Identity Type string for SystemAssigned, UserAssigned, or both
if args.user_assigned_identity:
    print("[+] Identity Type is SystemAssigned, UserAssigned")
    identity_type = "SystemAssigned, UserAssigned"

# Check to make sure there is at least one endpoint created here
if args.endpoints_count:
    vmcount = int(args.endpoints_count)
    if vmcount < 1:
        print("[-] This generator requires at least one VM to be created")
        print("[-] Set:  --endpoints 1 or greater")
        exit()
else:
    print("[-] This generator requires at least one VM to be created")
    print("[-] Set:  --endpoints 1 or greater")
    exit()

# get Local Admin 
default_input_admin = ""
if args.admin_set:
    default_input_admin= args.admin_set
    print("[+] Local Admin account name:  ",default_input_admin)
    logging.info('[+] Local Admin account name: %s', default_input_admin)

# get input password
default_input_password = ""
if args.password_set:
    default_input_password = args.password_set
    print("[+] Password desired for all users:  ",default_input_password)
    logging.info('[+] Password desired for all users: %s', default_input_password)

def get_password():

    #length of password
    length = 10 

    lower = string.ascii_lowercase
    upper = string.ascii_uppercase
    num = string.digits
    all = lower + upper + num

    # create blank password string / array
    password = []
    # at least one lower
    password.append(random.choice(lower))
    # at least one upper
    password.append(random.choice(upper))
    # at least one number 
    password.append(random.choice(num))
    for i in range(1, length - 2):
        if len(password) < length:
            password.append(random.choice(all))

    random.shuffle(password)

    final_random_password = ''.join(password)

    if args.password_set:
        return default_input_password 
    else:
        return final_random_password 

#### ACTIVE DIRECTORY CONFIGURATION
### Default Domain / Default AD Domain
ad_users_csv = "ad_users.csv"
default_aduser_password = get_password() 
default_domain = "rtc.local"
default_winrm_username = ""
default_winrm_password = get_password() 
default_admin_username = "RTCAdmin"
default_admin_password = get_password() 
default_da_password = get_password() 

# Get the Admin account if specified
if args.admin_set:
    default_admin_username = args.admin_set

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
        print(    "[-] Example:  python3 aadjoin.py -u acme.io --user_identity reader")
        print("    [-] Example:  python3 aadjoin.py -u acme.io --user_identity contributor")
        print("    [-] Example:  python3 aadjoin.py -u acme.io --user_identity owner")
        exit(1)

# duplicate count for created AD users
duplicate_count = 0

# Parsing some of the arguments
if not args.endpoints_count:
    print("[+] Windows 10 Pro Endpoints: 0")
    logging.info('[+] Windows 10 Pro Endpoints: 0')
    args.endpoints_count = 0 
else:
    print("[+] Number of Windows 10 Pro endpoints desired: ", args.endpoints_count)
    logging.info('[+] Number of Windows 10 Pro endpoints desired: %s', args.endpoints_count)

# parse the resource group name if specified
default_rg_name = "PurpleCloud"
if not args.resource_group:
    print("[+] Using default Resource Group Name: ", default_rg_name)
    logging.info('[+] Using default Resource Group Name: %s', default_rg_name)
else:
    default_rg_name = args.resource_group
    print("[+] Using Resource Group Name: ", default_rg_name)
    logging.info('[+] Using Resource Group: %s', default_rg_name)

# parse the Azure location if specified
supported_azure_locations = ['westus', 'westus2', 'eastus', 'centralus', 'centraluseuap', 'southcentralus' , 'northcentralus', 'westcentralus', 'eastus2', 'eastus2euap', 'brazilsouth', 'brazilus', 'northeurope', 'westeurope', 'eastasia', 'southeastasia', 'japanwest', 'japaneast', 'koreacentral', 'koreasouth', 'southindia', 'westindia', 'centralindia', 'australiaeast', 'australiasoutheast', 'canadacentral', 'canadaeast', 'uksouth', 'ukwest', 'francecentral', 'francesouth', 'australiacentral', 'australiacentral2', 'uaecentral', 'uaenorth', 'southafricanorth', 'southafricawest', 'switzerlandnorth', 'switzerlandwest', 'germanynorth', 'germanywestcentral', 'norwayeast', 'norwaywest', 'brazilsoutheast', 'westus3', 'swedencentral', 'swedensouth'
]
default_location = "eastus"
if not args.location:
    print("[+] Using default location: ", default_location)
    logging.info('[+] Using default location: %s', default_location)
else:
    default_location = args.location
    if default_location in supported_azure_locations:
        # this is a supported Azure location
        print("[+] Using Azure location: ", default_location)
        logging.info('[+] Using Azure location: %s', default_location)
    else:
        print("[-] This is not a supported azure location: ",default_location)
        print("[-] Check the supported_azure_locations if you need to add a new official Azure location")
        exit()

# Names of the terraform files
tmain_file = "main_aadjoin.tf"
tproviders_file = "providers.tf"
tnet_file = "network_aadjoin.tf"
tnsg_file = "nsg_aadjoin.tf"

# Azure AD users terraform file that is created from this script
# This creates the terraform file that is used by terraform containing users
tu_file = "users.tf"
# This creates the terraform file for Azure AD role assignments 
tr_file = "roles.tf"

### NETWORK CONFIGURATION
### ADD ADDITIONAL NETWORKS BELOW
### Configuration for VNets
config_vnets = [
    {
        "name":"vnet1",
        "prefix":"10.100.0.0/16",
        "type":"default"
    }
]
### Configuration for Subnets
config_subnets = [
    { 
        "name":"ad_subnet",
        "prefix":"10.100.10.0/24",
        "type":"ad_vlan"
    },
    {
        "name":"user_subnet",
        "prefix":"10.100.20.0/24",
        "type":"user_vlan"
    },
    {
        "name":"security_subnet",
        "prefix":"10.100.30.0/24",
        "type":"sec_vlan"
    },
    {
        "name":"attack_subnet",
        "prefix":"10.100.40.0/24",
        "type":""
    }
]

# A list of users
users_list = []

# AAD Users csv file
users_csv = "azure_users.csv"

# AAD email addresses
emails_txt = "azure_emails.txt"

# AAD usernames
usernames_txt = "azure_usernames.txt"

# counter for users added to the list
users_added = 0

# duplicate count
duplicate_count = 0

# default AD user count
default_aad_user_count = 10 

# Parsing some of the arguments
if not args.user_count:
    print("[+] No users specified ~ creating users by default: ", default_aad_user_count)
    args.user_count = default_aad_user_count 
else:
    print("[+] Number of users desired: ", args.user_count)

if not args.upn_suffix:
    print("[-] No upn_suffix specified")
    print("    [-] A upn (User Principal Name) Suffix must be specified in order to create users")
    print("    [-] Suffix can be a custom domain name you have added to Azure")
    print("    [-] Or the default, which is your tenant username + .onmicrosoft.com")
    print("    [-] Example with custom domain:")
    print("    [-] % python3 aadjoin.py -c 20 -u acme.io")
    print("    [-] Example with default tenant username + onmicrosoft.com:")
    print("    [-] % python3 aadjoin.py -c 20 -u acme.onmicrosoft.com")
    exit()
else:
    print("[+] upn suffix: ", args.upn_suffix)

### WINDOWS 10 CONFIGURATION / CONFIGURATION FOR WINDOWS 10 PRO ENDPOINTS
### The Default Configuration for all of the Windows 10 Endpoints
config_win10_endpoint = { 
    "hostname_base":"win10",
}

# Convert desired user count to integer
duser_count = int(args.user_count)

### Generate a user's name using Faker
### Insert the user into a list only if unique
### Loop until the users_added equals desired users
print("[+] Creating unique user list")
while users_added < duser_count:
    faker = Faker()
    first = faker.unique.first_name()
    last = faker.unique.last_name()
    display_name = first + " " + last
    if display_name in users_list:
        print("    [-] Duplicate user %s ~ not adding to users list" % (display_name))
        duplicate_count+=1
    else:
        users_list.append(display_name)
        users_added+=1

print("[+] Number of users added into list: ",len(users_list))
print("[+] Number of duplicate users filtered out: ",duplicate_count)

#### Create users csv file and dump full name, username, and email address
print("[+] Creating output files for Azure AD Users")
print("    [+] Users csv file: ", users_csv)
with open(users_csv, 'w') as f:
    for user in users_list:
        first = user.split()[0].lower()
        last = user.split()[1].lower()
        username = first + last
        upn = args.upn_suffix
        csv_line = user + "," + username + "," + username + "@" + upn
        f.writelines(csv_line)
        f.writelines('\n')

#### Creating usernames txt file
print("    [+] Username txt file: ", usernames_txt)
with open(usernames_txt, 'w') as f:
    for user in users_list:
        first = user.split()[0].lower()
        last = user.split()[1].lower()
        username = first + last
        f.writelines(username)
        f.writelines('\n')

#### Creating email addresses txt file
print("    [+] Email addresses txt file: ", emails_txt)
with open(emails_txt, 'w') as f:
    for user in users_list:
        first = user.split()[0].lower()
        last = user.split()[1].lower()
        username = first + last
        upn = args.upn_suffix
        f.writelines(username + "@" + upn)
        f.writelines('\n')

### Now write out proper terraform
terraform_users_template = '''
# Configure the Microsoft Azure Active Directory Provider
provider "azuread" {

}

### Note:  This upn_suffix must match the tenant username with *.onmicrosoft.com, or the custom domain that has been added
### This is the domain for all new Azure AD users
variable "upn_suffix" {
  default = "REPLACE_CUSTOM_STRING"
}

# Random Pet for Azure AD users (First part of password)
resource "random_pet" "rp_string" {
  length = 2
}

# Random String for Azure AD users (Second part of password)
resource "random_string" "my_password" {
  length  = 5
  special = false 
  upper   = true
}

locals {
  creds = "${random_pet.rp_string.id}-${random_string.my_password.id}"
}

output "azure_ad_details" {

  value = <<EOS

------------------------------------
Azure AD Security Lab Setup Complete
------------------------------------
Azure AD Password: ${local.creds}

EOS
}

# write azure ad user password to file
'''
user_template = '''
resource "azuread_user" "LINE1" {
  user_principal_name = "LINE2@${var.upn_suffix}"
  display_name        = "LINE3"
  mail_nickname       = "LINE4"
  password            = local.creds
}
'''

def get_role_template():
    template = '''
# Assign this user to role 1 
resource "azurerm_role_assignment" "vmadminUSER_NUMBER" {
  scope                = azurerm_resource_group.network.id
  role_definition_name = var.aad_role1 
  principal_id         = azuread_user.USER_NUMBER.object_id
}

# Assign this user to role 2 
resource "azurerm_role_assignment" "vmuserUSER_NUMBER" {
  scope                = azurerm_resource_group.network.id
  role_definition_name = var.aad_role2 
  principal_id         = azuread_user.USER_NUMBER.object_id
}
'''
    return template

if not args.upn_suffix:
    print("[+] No suffix defined ~ writing default to terraform file")
    terraform_users_template = terraform_users_template.replace("REPLACE_CUSTOM_STRING","")
else:
    terraform_users_template = terraform_users_template.replace("REPLACE_CUSTOM_STRING",args.upn_suffix)

### Write the beginning portion of terraform file
print("    [+] Terraform file: ", tu_file)
azure_ad_text_file = open(tu_file, "w")
n = azure_ad_text_file.write(terraform_users_template)

# rdp cheatsheet string
rdp_string = ""

### Loop and write all users in users_list to terraform file
counter = 0
for users in users_list:
    # increment the counter
    counter+=1

    # grab the template
    user_template_new = user_template

    # replace the line1 in terraform user template
    user_string = "user" + str(counter)
    user_template_new = user_template_new.replace("LINE1",user_string)

    # replace the line2 in terraform user with username in format first initial followed by last name
    first = users.split()[0].lower()
    last = users.split()[1].lower()
    # avoid duplicates with large lists of users by doing 'first_name' + 'last_name' for upn
    username = first + last
    user_template_new = user_template_new.replace("LINE2",username)

    # set the RDP string for RDP Azure AD login cheatsheet
    rdp_line = 'xfreerdp --no-nla -u "AzureAD\\' + username + '@' + args.upn_suffix + '" -p "${local.creds}" --ignore-certificate ${azurerm_public_ip.AZURERM_PUBLIC_IP_VAR_NAME.ip_address}'
   
    # append
    rdp_string+='\n'
    rdp_string+=rdp_line

    # replace the line3 in terraform user template with Display Name
    user_template_new = user_template_new.replace("LINE3",users)

    # replace the line4 in terraform user template
    user_template_new = user_template_new.replace("LINE4",username)

    # Write the user_template_new to file
    n = azure_ad_text_file.write(user_template_new)

# Close the file
azure_ad_text_file.close()

### Open the roles.tf file 

# Change the role1 below
role1 = "Virtual Machine Administrator Login"

# Change the role2 below
role2 = "Virtual Machine User Login"

print("[+] Creating output file for Azure Role Assignments")
print("    [+] Terraform file: ", tr_file)
print("    [+] Assigning all users to:", role1)
print("    [+] Assigning all users to:", role2)
azure_roles_file = open(tr_file, "w")

roles_beginning_template = '''
# Azure AD Roles Assignment file

variable "aad_role1" {
    default = "ROLE1"
}

variable "aad_role2" {
    default = "ROLE2"
}
'''
# get the roles beginning template
roles_beginning = roles_beginning_template

# change role1
roles_beginning = roles_beginning.replace("ROLE1", role1)
 
# change role2 
roles_beginning = roles_beginning.replace("ROLE2", role2)

# Write out role beginning
n = azure_roles_file.write(roles_beginning)

### Loop and write out the roles.tf file 
counter = 0
for users in users_list:
    # increment the counter
    counter+=1

    # grab the role template 
    role_template_new = get_role_template() 

    # replace the VM Administrator and User login line 
    user_string = "user" + str(counter)
    role_string = role_template_new.replace("USER_NUMBER",user_string)

    # Write the modified template to a file 
    n = azure_roles_file.write(role_string)

# Close the file
azure_roles_file.close()

### Windows 10 Pro endpoint count
### How many Windows 10 to build in this range?
win10_count = int(args.endpoints_count) 

### Do some inspection of the vnets to make sure no duplicates
default_vnet_name = ""
default_vnet_prefix = ""

vnet_names = []
vnet_prefixes = []
vnet_default_count = 0
for vnet in config_vnets:

    # network name
    net_name = vnet['name']
    vnet_names.append(net_name)

    # prefix
    prefix = vnet['prefix']
    vnet_prefixes.append(prefix)

    # type
    type = vnet['type']

    if ( type == "default" ):
        default_vnet_name = net_name
        default_vnet_prefix = prefix
        vnet_default_count+=1

def check_cidr_subnet(subnet_cidr_str):
    # Check the cidr or subnet to make sure it looks correct
    elements = subnet_cidr_str.split('.')
    if len(elements) != 4:
        print("[-] The subnet or CIDR is not in correct format:",subnet_cidr_str)
        print("[-] Correct examples include: 10.100.30.0/24")
        print("[-] Correct examples include: 10.100.0.0/16")
        return False

    octet1 = int(elements[0])
    if ((octet1 >= 0) and (octet1 <= 255)):
        pass
    else:
        print("[-] Error parsing the subnet or CIDR ~ not in correct format:", subnet_cidr_str)
        print("[-] Problem: ",octet1)
        return False

    octet2 = int(elements[1])
    if ((octet2 >= 0) and (octet2 <= 255)):
        pass
    else:
        print("[-] Error parsing the subnet or CIDR ~ not in correct format:", subnet_cidr_str)
        print("[-] Problem: ",octet2)
        return False

    octet3 = int(elements[2])
    if ((octet3 >= 0) and (octet3 <= 255)):
        pass
    else:
        print("[-] Error parsing the subnet or CIDR ~ not in correct format:", subnet_cidr_str)
        print("[-] Problem: ",octet3)
        return False

    last = elements[3]
    split_last = last.split('/')
    if len(split_last) != 2:
        print("[-] Error parsing the subnet or CIDR ~ not in correct format:", subnet_cidr_str)
        return False
    octet4 = int(split_last[0])
    if ((octet4 >= 0) and (octet4 <= 255)):
        pass
    else:
        print("[-] Error parsing the subnet or CIDR ~ not in correct format:", subnet_cidr_str)
        print("[-] Problem: ",octet4)
        return False

    octet5 = int(split_last[1])
    if ((octet5 >= 0) and (octet5 <= 32)):
        pass
    else:
        print("[-] Error parsing the subnet or CIDR ~ not in correct format:", subnet_cidr_str)
        print("[-] Problem: ",octet5)
        return False

    return True


# Check to make sure only one default vnet
if vnet_default_count != 1:
    print("[-] Only one default vnet type allowed")
    print('[-] Ensure that config_vnets has only one entry for "type":"default"')
    exit()

## Check for duplicate vnet names in config_vnets
if len(vnet_names) == len(set(vnet_names)):
    # No duplicate vnet names found
    pass
else:
    print("[-] Duplicate vnet names found")
    print("[-] Please ensure that each vnet name is unique in config_vnets")
    exit()

## Check for duplicate vnet prefixes in config_vnets
if len(vnet_prefixes) == len(set(vnet_prefixes)):
    # No duplicate vnet names found
    pass
else:
    print("[-] Duplicate vnet prefixes found")
    print("[-] Please ensure that each vnet prefix is unique in config_vnets")
    exit()

for prefix in vnet_prefixes:
    retval = check_cidr_subnet(prefix)
    if retval:
        pass
    else:
        print("[-] Invalid CIDR or subnet, exit")
        print("[-] Correct examples include: 10.100.30.0/24")
        print("[-] Correct examples include: 10.100.0.0/16")
        exit()

### Do some inspection of the subnets to make sure no duplicates
subnet_names = []
subnet_prefixes = []
user_vlan_count = 0
ad_vlan_count = 0
security_vlan_count = 0
security_subnet_prefix = ""
security_subnet_name = ""
ad_subnet_name = ""
ad_subnet_prefix = ""
user_subnet_name = ""
user_subnet_prefix = ""
for subnet in config_subnets:

    # network name
    net_name = subnet['name']
    subnet_names.append(net_name)

    # prefix
    prefix = subnet['prefix']
    subnet_prefixes.append(prefix)

    # type
    type = subnet['type']
    if type == 'user_vlan':
        #DEBUGprint("[+] Found user vlan name:", net_name)
        ## assign the user vlan name variable for later users
        user_subnet_name = net_name 
        user_subnet_prefix = prefix 
        user_vlan_count+=1
    elif (type == 'ad_vlan'):
        #DEBUGprint("[+] Found ad vlan name:", net_name)
        ad_subnet_prefix = prefix 
        ad_subnet_name = net_name 
        ad_vlan_count+=1
    elif (type == 'security_vlan'):
        security_subnet_prefix = prefix 
        security_subnet_name = net_name 
        security_vlan_count+=1
    else:
        pass

## Check for duplicate subnet names in config_subnets
if len(subnet_names) == len(set(subnet_names)):
    # No duplicate subnet names found
    pass
else:
    print("[-] Duplicate subnet names found")
    print("[-] Please ensure that each subnet name is unique in config_subnets")
    exit()

## Check for duplicate subnet prefixes in config_subnets
if len(subnet_prefixes) == len(set(subnet_prefixes)):
    # No duplicate subnet names found
    pass
else:
    print("[-] Duplicate subnet prefixes found")
    print("[-] Please ensure that each subnet prefix is unique in config_subnets")
    exit()

# Check to make sure more than one user_vlan is not enabled
if user_vlan_count > 1:
    print("[-] user vlans greater than 1.  Please specify one only one user vlan")

# Check to make sure more than one ad_vlan is not enabled
if ad_vlan_count > 1:
    print("[-] ad vlans greater than 1.  Please specify one only one ad vlan")

for prefix in subnet_prefixes:
    retval = check_cidr_subnet(prefix)
    if retval:
        pass
    else:
        print("[-] Invalid CIDR or subnet, exit")
        print("[-] Correct examples include: 10.100.30.0/24")
        print("[-] Correct examples include: 10.100.0.0/16")
        exit()

###
# Beginning of templates
###

# user_subnet start IP address
# If the user subnet is 10.100.30.0/24: 
# start the workstations at 10.100.30.x where x is first_ip_user_subnet variable 
first_ip_user_subnet = "10"

def get_endpoint_template():

    template = '''
variable "ENDPOINT_IP_VAR_NAME" {
  default = "ENDPOINT_IP_DEFAULT"
}

variable "ADMIN_USERNAME_VAR_NAME" {
  default = "ADMIN_USERNAME_DEFAULT"
}

variable "ADMIN_PASSWORD_VAR_NAME" {
  default = "ADMIN_PASSWORD_DEFAULT"
}

variable "ENDPOINT_HOSTNAME_VAR_NAME" {
  default = "ENDPOINT_HOSTNAME_DEFAULT"
}

resource "azurerm_public_ip" "AZURERM_PUBLIC_IP_VAR_NAME" {
  name                = "${var.ENDPOINT_HOSTNAME_VAR_NAME}-public-ip-${random_string.suffix.id}"
  location            = var.location
  resource_group_name = "${var.resource_group_name}-${random_string.suffix.id}"
  allocation_method   = "Static"

  depends_on = [azurerm_resource_group.network]
}

resource "azurerm_network_interface" "AZURERM_NETWORK_INTERFACE_VAR_NAME" {
  name                = "${var.ENDPOINT_HOSTNAME_VAR_NAME}-int-nic-${random_string.suffix.id}"
  location            = var.location
  resource_group_name = "${var.resource_group_name}-${random_string.suffix.id}"
  internal_dns_name_label = "${var.ENDPOINT_HOSTNAME_VAR_NAME}-${random_string.suffix.id}"

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.SUBNET_NAME_VARIABLE.id
    private_ip_address_allocation = "Static"
    private_ip_address = var.ENDPOINT_IP_VAR_NAME
    public_ip_address_id = azurerm_public_ip.AZURERM_PUBLIC_IP_VAR_NAME.id

  }
  depends_on = [azurerm_resource_group.network]
}

locals {
  WIN10VMNAME_VAR_NAME = var.ENDPOINT_HOSTNAME_VAR_NAME 
  WIN10VMFQDN_VAR_NAME = "${local.WIN10VMNAME_VAR_NAME}.DEFAULT_DOMAIN"
  WIN10CUSTOMDATAPARAMS_VAR_NAME   = "Param($RemoteHostName = \\"${local.WIN10VMFQDN_VAR_NAME}\\", $ComputerName = \\"${local.WIN10VMNAME_VAR_NAME}\\")"
  WIN10CUSTOMDATACONTENT_VAR_NAME  = base64encode(join(" ", [local.WIN10CUSTOMDATAPARAMS_VAR_NAME, data.template_file.PS_TEMPLATE_VAR_NAME.rendered ]))
}

data "template_file" "PS_TEMPLATE_VAR_NAME" {
  template = file("${path.module}/files/win10/bootstrap-win10-aadjoin.ps1.tpl")

  vars  = {
    admin_username            = var.ADMIN_USERNAME_VAR_NAME
    admin_password            = var.ADMIN_PASSWORD_VAR_NAME
  }
}

resource "local_file" "DEBUG_BOOTSTRAP_SCRIPT_VAR_NAME" {
  content = data.template_file.PS_TEMPLATE_VAR_NAME.rendered
  filename = "${path.module}/output/win10/bootstrap-${var.ENDPOINT_HOSTNAME_VAR_NAME}-aadjoin.ps1"
}

resource "azurerm_windows_virtual_machine" "AZURERM_WINDOWS_VIRTUAL_MACHINE_VAR_NAME" {
  name                          = "${local.WIN10VMNAME_VAR_NAME}-${random_string.suffix.id}"
  resource_group_name           = "${var.resource_group_name}-${random_string.suffix.id}"
  location                      = var.location
  size                       = "SIZE_WIN10"
  computer_name  = local.WIN10VMNAME_VAR_NAME
  admin_username = var.ADMIN_USERNAME_VAR_NAME
  admin_password = var.ADMIN_PASSWORD_VAR_NAME
  provision_vm_agent        = true
  custom_data    = local.WIN10CUSTOMDATACONTENT_VAR_NAME

  identity {
    type         = var.identity_type 
    IDENTITY_IDS
  }

  network_interface_ids         = [
    azurerm_network_interface.AZURERM_NETWORK_INTERFACE_VAR_NAME.id,
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
      content      = "<AutoLogon><Password><Value>${var.ADMIN_PASSWORD_VAR_NAME}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.ADMIN_USERNAME_VAR_NAME}</Username></AutoLogon>"
      setting = "AutoLogon"
  }

  additional_unattend_content {
      content      = file("${path.module}/files/win10/FirstLogonCommands.xml")
      setting = "FirstLogonCommands"
  }

  depends_on = [
    azurerm_network_interface.AZURERM_NETWORK_INTERFACE_VAR_NAME,
  ]
}

resource "local_file" "HOSTS_CFG_VAR_NAME" {
  content = templatefile("${path.module}/files/win10/hosts.tpl",
    {
      ip    = azurerm_public_ip.AZURERM_PUBLIC_IP_VAR_NAME.ip_address
      auser = var.ADMIN_USERNAME_VAR_NAME
      apwd  = var.ADMIN_PASSWORD_VAR_NAME
    }
  )
  filename = "${path.module}/hosts-${var.ENDPOINT_HOSTNAME_VAR_NAME}.cfg"
}

output "windows_endpoint_details_AZURERM_WINDOWS_VIRTUAL_MACHINE_VAR_NAME" {
  value = <<EOS
-------------------------
Virtual Machine ${azurerm_windows_virtual_machine.AZURERM_WINDOWS_VIRTUAL_MACHINE_VAR_NAME.computer_name} 
-------------------------
Computer Name:  ${azurerm_windows_virtual_machine.AZURERM_WINDOWS_VIRTUAL_MACHINE_VAR_NAME.computer_name}
Private IP: ${var.ENDPOINT_IP_VAR_NAME}
Public IP:  ${azurerm_public_ip.AZURERM_PUBLIC_IP_VAR_NAME.ip_address}
local Admin:  ${azurerm_windows_virtual_machine.AZURERM_WINDOWS_VIRTUAL_MACHINE_VAR_NAME.admin_username}
local password: ${var.ADMIN_PASSWORD_VAR_NAME} 

---------------------------------
RDP Cheatsheet for Azure AD Login
---------------------------------
RDP_USERS_LIST

EOS
}

resource "azurerm_virtual_machine_extension" "aad_login_AZURERM_WINDOWS_VIRTUAL_MACHINE_VAR_NAME" {

  name                       = "AADLoginForWindows"
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "1.0"
  virtual_machine_id         = azurerm_windows_virtual_machine.AZURERM_WINDOWS_VIRTUAL_MACHINE_VAR_NAME.id
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = false


  depends_on = [azurerm_windows_virtual_machine.AZURERM_WINDOWS_VIRTUAL_MACHINE_VAR_NAME]
}

'''
    return template


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

def get_main_template():
    template = '''

data "azurerm_subscription" "aadjoin" {
}

# Create the User Assigned Managed Identity
resource "azurerm_user_assigned_identity" "uai" {
  resource_group_name = azurerm_resource_group.network.name
  location            = var.location
  name                = var.identity_name
}

variable "identity_name" {
  default = "uaidentity"
}

variable "identity_type" {
  default = "IDENTITY_TYPE"
}

# Assign the reader role on the VM to the Managed Identity
resource "azurerm_role_assignment" "uai" {
  #Scope to the key vault in line below
  #scope                = azurerm_key_vault.example.id
  #Scope to the subscription in line below
  scope                = data.azurerm_subscription.aadjoin.id
  role_definition_name = "ROLE_DEFINITION_NAME"
  principal_id         = azurerm_user_assigned_identity.uai.principal_id
}

locals {
  storage_account_name = "purplecloud${random_string.suffix.id}"
}

variable "location" {
  default = "DEFAULT_LOCATION"
}

variable "resource_group_name" {
  default = "RG_NAME_DEFAULT"
}

variable "storage_container_name" {
  default = "staging"
}

variable "azure_users_file" {
  default = "ad_users.csv"
}

variable "azure_aadconnect_file" {
  default = "AzureADConnect.msi"
}

# Random string for resources
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false 
}

# Specify the resource group
resource "azurerm_resource_group" "network" {
  name     = "${var.resource_group_name}-${random_string.suffix.id}"
  location = var.location
}

# Create a storage account
resource "azurerm_storage_account" "storage-account" {
  name                     = local.storage_account_name 
  resource_group_name      = "${var.resource_group_name}-${random_string.suffix.id}"
  location                 = var.location 
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_nested_items_to_be_public = true

  depends_on = [azurerm_resource_group.network]
}

# Create storage container
resource "azurerm_storage_container" "storage-container" {
  name                  = var.storage_container_name 
  storage_account_name  = azurerm_storage_account.storage-account.name
  container_access_type = "blob"

  depends_on = [azurerm_resource_group.network]
}

output "rg_name" {
  value   = "${var.resource_group_name}-${random_string.suffix.id}"
}

'''

    return template 

### BEGIN NETWORK TEMPLATE
### This defines the networks.tf
def get_vnet_template():

    template = '''
# the address space for the vnet
variable "VNET_NAME_VARIABLE-address-space" {
  default = "VNET_ADDRESS_SPACE_VALUE"
}

# Create the VNet 
resource "azurerm_virtual_network" "VNET_NAME_VARIABLE-vnet" {
  name                = "${var.resource_group_name}-${random_string.suffix.id}-vnet"
  address_space       = [var.VNET_NAME_VARIABLE-address-space]
  location            = var.location
  resource_group_name = "${var.resource_group_name}-${random_string.suffix.id}"

  depends_on = [azurerm_resource_group.network]
}
'''
    return template

def get_subnet_template():

    template = '''

variable "SUBNET_NAME_VARIABLE-name" {
  default = "SUBNET_NAME_VARIABLE"
}

variable "SUBNET_NAME_VARIABLE-prefix" {
  default = "SUBNET_PREFIX_VALUE"
}

# Create the SUBNET_NAME_VARIABLE subnet
resource "azurerm_subnet" "SUBNET_NAME_VARIABLE-subnet" {
  name                 = "${var.resource_group_name}-${var.SUBNET_NAME_VARIABLE-name}-${random_string.suffix.id}"
  resource_group_name  = "${var.resource_group_name}-${random_string.suffix.id}"
  virtual_network_name = azurerm_virtual_network.DEFAULT_VNET_NAME-vnet.name
  address_prefixes       = [var.SUBNET_NAME_VARIABLE-prefix]

  depends_on = [azurerm_resource_group.network]
}

resource "azurerm_subnet_network_security_group_association" "nsg-association-SUBNET_NAME_VARIABLE" {
  subnet_id            = azurerm_subnet.SUBNET_NAME_VARIABLE-subnet.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
  depends_on = [azurerm_resource_group.network]
}
'''
    return template
### END NETWORK TEMPLATE

### BEGIN NSG TEMPLATE - Begin the Azure Network Security Groups
### nsg.tf
def get_nsg_template():
    template = '''

# Thanks to @christophetd and his Github.com/Adaz project for this little code
data "http" "firewall_allowed" {
  url = "http://ifconfig.so"
}

locals {
  src_ip = chomp(data.http.firewall_allowed.response_body)
  #src_ip = "0.0.0.0/0"
}

# This is the src_ip for white listing Azure NSGs
# This is going to be replaced by the data http resource above
# allow every public IP address by default
variable "src_ip" {
  default = "SRC_PREFIX_VALUE"
}

resource "azurerm_network_security_group" "nsg1" {
  name                = "${var.resource_group_name}-nsg1"
  location            = var.location
  resource_group_name = "${var.resource_group_name}-${random_string.suffix.id}"
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
  security_rule {
    name                       = "allow-https"
    description                = "Windows Remote Managment (HTTPS-In)"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = local.src_ip
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-ssh"
    description                = "Allow SSH (SSH-In)"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = local.src_ip 
    destination_address_prefix = "*"
  }
  depends_on = [azurerm_resource_group.network]
}
'''
    return template
### END NSG TEMPLATE

# Get the endpoint.tf template
endpoint_template = get_endpoint_template()

# replace the user assigned identity if applicable
#identity_ids_line = "identity_ids = [azurerm_user_assigned_identity.uai.id]"
#print("[+] Setting a user assigned identity identity_ids_line")
#endpoint_template = endpoint_template.replace("IDENTITY_IDS",identity_ids_line)

# Get the main.tf template
main_template = get_main_template()

# replace the user assigned role if necessary
# replace the role definition name for the user assigned identity
if args.user_assigned_identity:
    identity = args.user_assigned_identity
    if identity.lower() == 'reader':
        main_template = main_template.replace("ROLE_DEFINITION_NAME","Reader")
    elif identity.lower() == 'contributor':
        main_template = main_template.replace("ROLE_DEFINITION_NAME","Contributor")
    elif identity.lower() == 'owner':
        main_template = main_template.replace("ROLE_DEFINITION_NAME","Owner")
else:
    main_template = main_template.replace("ROLE_DEFINITION_NAME","Reader")

# replace the identity type in block
main_template = main_template.replace("IDENTITY_TYPE",identity_type)
print("[+] Setting identity type for VM to",identity_type)

# replace the identity_ids as required
#identity_ids_line = ""
#if identity_type == "SystemAssigned":
#    identity_ids_line = ""
#else:
    #It must be 'SystemAssigned, UserAssigned' or 'UserAssigned'
#    identity_ids_line = "identity_ids = [azurerm_user_assigned_identity.uai.id]"
    #print("[+] Setting a user assigned identity identity_ids_line")
#Finally, replace
#main_template = main_template.replace("IDENTITY_IDS",identity_ids_line)

# Get the providers.tf template
providers_template = get_providers_template()

# replace the RG name
main_template = main_template.replace("RG_NAME_DEFAULT", default_rg_name)

# replace the Azure location
main_template = main_template.replace("DEFAULT_LOCATION", default_location)

# Write the main.tf
main_text_file = open(tmain_file, "w")
n = main_text_file.write(main_template)
print("[+] Creating the main terraform file: ",tmain_file)
logging.info('[+] Creating the main terraform file: %s', tmain_file)
main_text_file.close()

# Write the providers.tf
providers_text_file = open(tproviders_file, "w")
n = providers_text_file.write(providers_template)
print("[+] Creating the providers terraform file: ",tproviders_file)
logging.info('[+] Creating the providers terraform file: %s', tproviders_file)
providers_text_file.close()

# open the network.tf
net_text_file = open(tnet_file, "w")

### Loop and write out all vnets
default_prefix_name = ""
for vnet in config_vnets:

    # get vnet template
    default_vnet_template = get_vnet_template()

    # network name
    net_name = vnet['name']

    # replace the variable name for vnet address space
    new_vnet_string = default_vnet_template.replace("VNET_NAME_VARIABLE",net_name)

    # prefix
    prefix = vnet['prefix']

    # replace the prefix value 
    new_vnet_string = new_vnet_string.replace("VNET_ADDRESS_SPACE_VALUE",prefix)

    # Write this vnet to file
    n = net_text_file.write(new_vnet_string)

### Loop and write out all subnets 
for subnet in config_subnets:

    # get subnet template
    default_subnet_template = get_subnet_template()

    # network name
    net_name = subnet['name']

    # replace the variable name for subnet name 
    new_subnet_string = default_subnet_template.replace("SUBNET_NAME_VARIABLE",net_name)

    # prefix
    prefix = subnet['prefix']

    # replace the prefix value for subnet name 
    new_subnet_string = new_subnet_string.replace("SUBNET_PREFIX_VALUE", prefix)

    # replace the default vnet variable name 
    #print("[+] Assigning this subnet to default vnet:", default_vnet_name)
    new_subnet_string = new_subnet_string.replace("DEFAULT_VNET_NAME", default_vnet_name)

    # Write this subnet to networks file
    n = net_text_file.write(new_subnet_string)

# Close the networks.tf file
net_text_file.close()

# open the nsg.tf
nsg_text_file = open(tnsg_file, "w")

# get the nsg template
default_nsg_template = get_nsg_template()

# Write the nsg.tf
n = nsg_text_file.write(default_nsg_template)
print("[+] Creating the nsg terraform file: ",tnsg_file)
logging.info('[+] Creating the nsg terraform file: %s', tnsg_file)
nsg_text_file.close()

#########
#### Beginning of build the Windows 10 Pro systems
#########

print("[+] Building Windows 10 Pro")
logging.info('[+] Building the Windows 10 Pro')
print("  [+] Number of systems to build: ",win10_count)
logging.info('[+] Number of systems to build: %s', win10_count)
if (win10_count > 0):
    print("    [+] Getting default configuration template for Windows 10 Pro")
    logging.info('[+] Getting default configuration template for Windows 10 Pro')
    hostname_base = config_win10_endpoint['hostname_base']
    print("    [+] Base Hostname:", hostname_base) 
    logging.info('[+] Base Hostname: %s', hostname_base)
    admin_username = default_admin_username 
    print("    [+] Administrator Username:",admin_username) 
    logging.info('[+] Administrator Username: %s', admin_username)
    admin_password = default_admin_password 
    print("    [+] Administrator Password:",admin_password) 
    logging.info('[+] Administrator Password: %s', admin_password)
    print("    [+] Subnet Association:", user_subnet_name)
    logging.info('[+] Subnet Association: %s', user_subnet_name)

    i = 0
    last_octet_int = int(first_ip_user_subnet)
    for i in range(win10_count):

        #number suffix for unique host variable naming
        num_suffix = i + 1

        print("  [+] Building Windows 10 Pro Endpoint", num_suffix)
        logging.info('[+] Building Windows 10 Pro Endpoint: %s', num_suffix)
        this_hostname = hostname_base + "-" + str(num_suffix)

        print("    [+] Hostname:", this_hostname )
        logging.info('[+] Hostname: %s', this_hostname)
        last_octet_str = str(last_octet_int)
        this_ipaddr = user_subnet_prefix.replace("0/24",last_octet_str)

        print("    [+] IP address:", this_ipaddr )
        logging.info('[+] IP address: %s', this_ipaddr)

        # Write the endpoint.tf
        this_endpoint_template = get_endpoint_template()
        
        # replace the variable endpoint_ip
        new_endpoint_template = this_endpoint_template.replace("ENDPOINT_IP_VAR_NAME", "endpoint-ip-" + this_hostname)
        new_endpoint_template = new_endpoint_template.replace("ENDPOINT_IP_DEFAULT", this_ipaddr)

        # replace the variable admin_username 
        new_endpoint_template = new_endpoint_template.replace("ADMIN_USERNAME_VAR_NAME", "admin-username-" + this_hostname)
        new_endpoint_template = new_endpoint_template.replace("ADMIN_USERNAME_DEFAULT", admin_username)

        # replace the variable admin_password 
        new_endpoint_template = new_endpoint_template.replace("ADMIN_PASSWORD_VAR_NAME", "admin-password-" + this_hostname)
        new_endpoint_template = new_endpoint_template.replace("ADMIN_PASSWORD_DEFAULT", admin_password)

        # replace the variable endpoint_hostname for this Windows 10 Pro 
        new_endpoint_template = new_endpoint_template.replace("ENDPOINT_HOSTNAME_VAR_NAME", "endpoint_hostname-" + this_hostname)
        new_endpoint_template = new_endpoint_template.replace("ENDPOINT_HOSTNAME_DEFAULT", this_hostname)

        # replace for the RDP cheatsheet
        new_endpoint_template = new_endpoint_template.replace("RDP_USERS_LIST", rdp_string)

        # replace the variable azurerm_public_ip for this Windows 10 Pro 
        new_endpoint_template = new_endpoint_template.replace("AZURERM_PUBLIC_IP_VAR_NAME", "win10-external-ip-" + this_hostname)

        # replace the variable azurerm_network_interface for this Windows 10 Pro 
        new_endpoint_template = new_endpoint_template.replace("AZURERM_NETWORK_INTERFACE_VAR_NAME", "win10-primary-nic-" + this_hostname)
  
        # replace the locals for this Windows 10 Pro 
        new_endpoint_template = new_endpoint_template.replace("WIN10VMNAME_VAR_NAME", "win10vmname-" + this_hostname)
        new_endpoint_template = new_endpoint_template.replace("WIN10VMFQDN_VAR_NAME", "win10vmfqdn-" + this_hostname)
        new_endpoint_template = new_endpoint_template.replace("WIN10CUSTOMDATAPARAMS_VAR_NAME", "win10custom-data-params-" + this_hostname)
        new_endpoint_template = new_endpoint_template.replace("WIN10CUSTOMDATACONTENT_VAR_NAME", "win10custom-data-content-" + this_hostname)

        # replace the ps template name for this Windows 10 Pro 
        new_endpoint_template = new_endpoint_template.replace("PS_TEMPLATE_VAR_NAME", "ps-template-" + this_hostname)

        # replace the debug bootstrap script name for this Windows 10 Pro 
        new_endpoint_template = new_endpoint_template.replace("DEBUG_BOOTSTRAP_SCRIPT_VAR_NAME", "debug-bootstrap-script-" + this_hostname)

        # replace the azurerm_windows_virtual_machine_name name for this Windows 10 Pro 
        new_endpoint_template = new_endpoint_template.replace("AZURERM_WINDOWS_VIRTUAL_MACHINE_VAR_NAME", "azurerm-vm-" + this_hostname)

        # replace the local hosts config file for this Windows 10 Pro 
        new_endpoint_template = new_endpoint_template.replace("HOSTS_CFG_VAR_NAME", "hosts-cfg-" + this_hostname)
  
        # replace the bootstrap pwsh script file for this Windows 10 Pro 
        new_endpoint_template = new_endpoint_template.replace("BOOTSTRAP_FILE_NAME", "bootstrap-" + this_hostname + ".ps1")

        # replace the user subnet name variable for this Windows 10 Pro 
        new_endpoint_template = new_endpoint_template.replace("SUBNET_NAME_VARIABLE", user_subnet_name + "-subnet" )

        # replace the Windows 10 instance size 
        new_endpoint_template = new_endpoint_template.replace("SIZE_WIN10", size_win10 )

        # replace the user assigned identity if applicable
        identity_ids_line = ""
        if identity_type == "SystemAssigned":
            identity_ids_line = ""
        else:
            identity_ids_line = "identity_ids = [azurerm_user_assigned_identity.uai.id]"
            #print("[+] Setting a user assigned identity identity_ids_line")
        #Finally, replace
        new_endpoint_template = new_endpoint_template.replace("IDENTITY_IDS",identity_ids_line)

        this_file = this_hostname + ".tf"
        endpoint_text_file = open(this_file, "w")
        n = endpoint_text_file.write(new_endpoint_template)
        print("    [+] Created terraform:", this_file )
        logging.info('[+] Created terraform: %s', this_file)
        endpoint_text_file.close()

        #increment the last octet for each new Win10 Pro
        last_octet_int+=1
### End of build the Windows 10 Pro systems
