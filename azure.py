from faker import Faker
import random
import argparse
import os
import subprocess
import urllib.request
import secrets
import string
import logging


# Override whitelist means that it will try to auto-detect the public IP address and override the whitelist_nsg variable
# If override is true, it tries to find public IP address automatically
# If you don't want this, set it to false and you can control the whitelist IP address with 'whitelist_nsg" variable 
override_whitelist = True 

# Azure NSG
# By default, allow all IP addresses for Azure NSGs
whitelist_nsg = "*"

# logfile configuration
logging.basicConfig(format='%(asctime)s %(message)s', filename='ranges.log', level=logging.INFO)

# The instance size for each system
size_win10 = "Standard_A1"
size_dc    = "Standard_A1"
size_helk  = "Standard_DS3_v2"

# dc_ip - The domain controller IP address
dc_ip = ""

### automatically find pubblic IP address and return it if found 
def check_public_ip_addr():
    try:
        ext_ip = urllib.request.urlopen('http://ifconfig.me').read().decode('utf8')
        print("[+] Public IP address detected: ", ext_ip)
        logging.info('[+] Public IP address detected: %s', ext_ip)
        return ext_ip
    except:
        print("An error occured with urllib")

if override_whitelist:
    retval = check_public_ip_addr()
    if not retval: 
        pass
        # Something went wrong so set default to *
    else:
        print("[+] Setting Azure NSG Whitelist to: ", retval)
        logging.info('[+] Setting Azure NSG Whitelist to: %s', retval)
        whitelist_nsg = retval
# End Azure NSG Whitelist section

# argparser stuff
parser = argparse.ArgumentParser(description='A script to create Azure infrastructure')

# Add argument for count of Windows 10 Pro endpoints 
parser.add_argument('-e', '--endpoints', dest='endpoints_count')

# Add argument for resource group name 
parser.add_argument('-r', '--resource_group', dest='resource_group')

# Add argument for location 
parser.add_argument('-l', '--location', dest='location')

# Add argument for enabling HELK (Hunting + ELK) server 
parser.add_argument('-he', '--helk', dest='helk_enable', action='store_true')

# Add argument for enabling Domain Controller 
parser.add_argument('-dc', '--domain_controller', dest='dc_enable', action='store_true')

# Add argument for Active Directory Domain 
parser.add_argument('-ad', '--ad_domain', dest='ad_domain')

# Add argument for Active Directory Users count 
parser.add_argument('-au', '--ad_users', dest='user_count')

# Add argument for  Local Administrator 
parser.add_argument('-u', '--admin', dest='admin_set')

# Add argument for password  
parser.add_argument('-p', '--password', dest='password_set')

# Add argument for domain_join 
parser.add_argument('-dj', '--domain_join', dest='domain_join', action='store_true')

# Add argument for auto login 
parser.add_argument('-al', '--auto_logon', dest='auto_logon', action='store_true')

# parse arguments
args = parser.parse_args()

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

#### Create Extra AD Users if desired
# Convert desired user count to integer
# counter for users added to the list
users_added = 0

def get_password():

    #length of password
    length = 10 

    lower = string.ascii_lowercase
    upper = string.ascii_uppercase
    num = string.digits
    all = lower + upper + num
    #temp = random.sample(all, length)
    #password = "".join(temp)

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
ad_groups = ["Marketing", "IT", "Legal", "Sales", "Executive", "Engineering"]

# Get the default domain if specified
if args.ad_domain:
    default_domain = args.ad_domain
    print("[+] Setting AD Domain to build AD DS:",default_domain)
    logging.info('[+] Setting AD Domain to build AD DS: %s', default_domain)
# Get the Admin account if specified
if args.admin_set:
    default_admin_username = args.admin_set

# duplicate count for created AD users
duplicate_count = 0
# Extra AD users beyond the default in default_ad_users
extra_users_list = [] 
all_ad_users = []
if args.user_count:
    duser_count = int(args.user_count)

    ### Generate a user's name using Faker
    ### Insert the user into a list only if unique
    ### Loop until the users_added equals desired users
    print("[+] Creating unique user list")
    logging.info('[+] Creating unique user list')
    while users_added < duser_count:
        faker = Faker()
        first = faker.unique.first_name()
        last = faker.unique.last_name()
        display_name = first + " " + last
        if display_name in extra_users_list:
            print("    [-] Duplicate user %s ~ not adding to users list" % (display_name))
            logging.info('[-] Duplicate user %s', display_name)
            duplicate_count+=1
        else:
            extra_users_list.append(display_name)
            user_dict = {"name":"", "pass":""}
            user_dict['name'] = display_name 
            user_dict['pass'] = default_aduser_password 
            all_ad_users.append(user_dict)
            users_added+=1
            #DEBUGprint("[+] Generated AD user:", display_name)

    print("[+] Number of users added into list: ",len(extra_users_list))
    logging.info('[+] Number of users added into list %d', len(extra_users_list))
    print("[+] Number of duplicate users filtered out: ",duplicate_count)
    logging.info('[+] Number of duplicate users filtered out: %s', duplicate_count)
### End of extra AD Users

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
default_location = "centralus"
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

# The default AD Users
# The groups field is the AD Group that will be automatically created
# An OU will be auto-created based on the AD Group name, and the Group will have OU path set to it 
default_ad_users = [
    {
        "name":"Lars Borgerson",
        "ou": "CN=users,DC=rtc,DC=local",
        "password": get_password(),
        "domain_admin":"",
        "groups":"IT"
    },
    {
        "name":"Olivia Odinsdottir",
        "ou": "CN=users,DC=rtc,DC=local",
        "password": get_password(),
        "domain_admin":"True",
        "groups":"IT"
    },
    {
        "name":"Liem Anderson",
        "ou": "CN=users,DC=rtc,DC=local",
        "password": get_password(),
        "domain_admin":"",
        "groups":"IT"
    },
    {
        "name":"John Nilsson",
        "ou": "CN=users,DC=rtc,DC=local",
        "password": get_password(),
        "domain_admin":"",
        "groups":"IT"
    },
    {
        "name":"Jason Lindqvist",
        "ou": "CN=users,DC=rtc,DC=local",
        "password": get_password(),
        "domain_admin":"True",
        "groups":"IT"
    },
]

# Parse the AD users to get one Domain Admin for bootstrapping systems
if args.dc_enable:
    da_count = 0
    for user in default_ad_users:

        # Set up a dictionary to store name and password
        user_dict = {'name': '', 'pass':''}
        user_dict['name'] = user['name'] 

        if user['domain_admin'].lower() == 'true':
            da_count+=1
            names = user['name'].split()
            default_winrm_username = names[0].lower() + names[1].lower()
            #DEBUGprint("[+] Default winrm username: ",default_winrm_username)
            default_winrm_password = user['password']
            #DEBUGprint("[+] Default winrm password: ",default_winrm_password)

            # set password to default domain admin password
            user_dict['pass'] = default_da_password
        else:
            # set password to default ad user password
            user_dict['pass'] = default_aduser_password

        # Append to all_ad_users
        all_ad_users.append(user_dict)

    if da_count >= 1:
        pass
    else:
        print("[-] At least one Domain Admin in default_ad_users must be enabled")
        exit()

# If set to True and if HELK server is enabled:
# Install the Winlogbeat
# and Velociraptor agent on Windows 10
# and export logs to helk server
default_install_agent = True

# install the velociraptor, winlogbeat agent
# and export siem logs
install_agent = False

# Install sysmon, false by default
install_sysmon = False

# Install art, false by default
install_art = False

# Names of the terraform files
tmain_file = "main.tf"
tnet_file = "network.tf"
tnsg_file = "nsg.tf"
thelk_file = "helk.tf"
tdc_file = "dc.tf"

# This is the base windows 10 file name.  Will be replaced with the number of endpoints:  win10-1.tf, win10-2.tf
# Each Windows 10 Pro will have its own dedicated terraform file ~ Easier to use and understand
twin10_file = "win10.tf"

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
        "name":"siem_subnet",
        "prefix":"10.100.30.0/24",
        "type":"siem_vlan"
    },
    {
        "name":"attack_subnet",
        "prefix":"10.100.40.0/24",
        "type":""
    }
]

### WINDOWS 10 CONFIGURATION / CONFIGURATION FOR WINDOWS 10 PRO ENDPOINTS
### The Default Configuration for all of the Windows 10 Endpoints
config_win10_endpoint = { 
    "hostname_base":"win10",
    "join_domain":"false",
    "auto_logon_domain_user":"false",
    "install_sysmon":"true",
    "install_art":"true",
}

## Check if domain_join argument is enabled
## If it is, set the configuration above
if args.domain_join:
    print("[+] Domain Join is set to true")
    logging.info('[+] Domain Join is set to true')
    config_win10_endpoint['join_domain'] = "true"

## Check if auto_logon argument is enabled
## If it is, set the configuration above
if args.auto_logon:
    print("[+] Auto Logon is set to true")
    logging.info('[+] Auto Logon is set to true')
    config_win10_endpoint['auto_logon_domain_user'] = "true"

## Check the configuration above
## Can only join the domain or auto logon domain users if dc enable
if config_win10_endpoint['join_domain'].lower() == 'true' or config_win10_endpoint['auto_logon_domain_user'].lower == 'true':
    if args.dc_enable:
        pass
    else:
        print("[-] The Domain controller option must be enabled for Domain Join or Auto Logon Domain Users")
        print("[-] Current setting for join_domain: ", config_win10_endpoint['join_domain'])
        print("[-] Current setting for auto_logon_domain_user: ", config_win10_endpoint['auto_logon_domain_user'])
        exit()

### Windows 10 Pro endpoint count
### How many Windows 10 to build in this range?
win10_count = int(args.endpoints_count) 

# check to make sure config_win10_endpoint is correct for true or false values
if config_win10_endpoint['join_domain'].lower() != 'false' and config_win10_endpoint['join_domain'].lower() != 'true':
    print("[-] Setting join_domain must be true or false")
    exit()
if config_win10_endpoint['auto_logon_domain_user'].lower() != 'false' and config_win10_endpoint['auto_logon_domain_user'].lower() != 'true':
    print("[-] Setting auto_logon_domain_user must be true or false")
    exit()
if config_win10_endpoint['install_sysmon'].lower() != 'false' and config_win10_endpoint['install_sysmon'].lower() != 'true':
    print("[-] Setting install_sysmon must be true or false")
    exit()
if config_win10_endpoint['install_art'].lower() != 'false' and config_win10_endpoint['install_art'].lower() != 'true':
    print("[-] Setting install_art must be true or false")
    exit()

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
        #DEBUGprint("[+] Found default vnet type for network name:", net_name)
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
siem_vlan_count = 0
siem_subnet_prefix = ""
siem_subnet_name = ""
ad_subnet_name = ""
ad_subnet_prefix = ""
helk_ip = ""
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
    elif (type == 'siem_vlan'):
        #DEBUGprint("[+] Found siem vlan name:", net_name)
        siem_subnet_prefix = prefix 
        siem_subnet_name = net_name 
        siem_vlan_count+=1
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

## Get helk_ip if helk is enabled
if args.helk_enable:
    if siem_vlan_count == 1:
        #print("[+] Analyzing ", siem_subnet_prefix)
        # This is the last octet of the helk_ip
        last_octet = "4"
        elements = siem_subnet_prefix.split('.')
        helk_ip = elements[0] + "." + elements[1] + "." + elements[2] + "." + last_octet
        #print("[+] HELK IP ", helk_ip)
    else:
        print("[-] Helk is enabled without a subnet assignment")
        print("[-] Set a type of siem_vlan to one of the subnets")
        exit()

# Check if helk is enabled
if args.helk_enable:
    print("[+] HELK server enabled", helk_ip)
    logging.info('[+] HELK server enabled: %s', helk_ip)
    if default_install_agent:
        install_agent = True
        if int(args.endpoints_count) > 0:
            print("[+] Installing velociraptor, winlogbeat agents on endpoints and exporting logs to HELK")
            logging.info('[+] Installing velociraptor, winlogbeat agents on endpoints and exporting logs to HELK')

## Get dc_ip if dc is enabled
if args.dc_enable:
    if ad_vlan_count == 1:
        #print("[+] Analyzing ", siem_subnet_prefix)
        # This is the last octet of the helk_ip
        last_octet = "4"
        elements = ad_subnet_prefix.split('.')
        dc_ip = elements[0] + "." + elements[1] + "." + elements[2] + "." + last_octet
        #print("[+] HELK IP ", helk_ip)
    else:
        print("[-] DC is enabled without a subnet assignment")
        print("[-] Set a type of ad_vlan to one of the subnets")
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

variable "JOIN_DOMAIN_VAR_NAME" {
  default = JOIN_DOMAIN_DEFAULT
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
    private_ip_address_allocation = "static"
    private_ip_address = var.ENDPOINT_IP_VAR_NAME
    public_ip_address_id = azurerm_public_ip.AZURERM_PUBLIC_IP_VAR_NAME.id

  }
  depends_on = [azurerm_resource_group.network]
}

locals {
  WIN10VMNAME_VAR_NAME = var.ENDPOINT_HOSTNAME_VAR_NAME 
  #WIN10VMFQDN_VAR_NAME = "${local.WIN10VMNAME_VAR_NAME}.rtcfingroup.local"
  WIN10VMFQDN_VAR_NAME = "${local.WIN10VMNAME_VAR_NAME}.DEFAULT_DOMAIN"
  WIN10CUSTOMDATAPARAMS_VAR_NAME   = "Param($RemoteHostName = \\"${local.WIN10VMFQDN_VAR_NAME}\\", $ComputerName = \\"${local.WIN10VMNAME_VAR_NAME}\\")"
  WIN10CUSTOMDATACONTENT_VAR_NAME  = base64encode(join(" ", [local.WIN10CUSTOMDATAPARAMS_VAR_NAME, data.template_file.PS_TEMPLATE_VAR_NAME.rendered ]))
}

data "template_file" "PS_TEMPLATE_VAR_NAME" {
  template = file("${path.module}/files/bootstrap-win10.ps1")

  vars  = {
    join_domain               = var.JOIN_DOMAIN_VAR_NAME ? 1 : 0
    install_sysmon            = INSTALL_SYSMON ? 1 : 0
    install_art               = INSTALL_ART ? 1 : 0
    install_agent             = INSTALL_AGENT ? 1 : 0
    auto_logon_domain_user    = AUTO_LOGON_SETTING ? 1 : 0
    dc_ip                     = "DC_IP" 
    helk_ip                   = "HELK_IP"
    endpoint_ad_user          = "ENDPOINT_AD_USER" 
    endpoint_ad_password      = "ENDPOINT_AD_PASSWORD" 
    winrm_username            = "WINRM_USERNAME" 
    winrm_password            = "WINRM_PASSWORD" 
    admin_username            = var.ADMIN_USERNAME_VAR_NAME
    admin_password            = var.ADMIN_PASSWORD_VAR_NAME
    ad_domain                 = "AD_DOMAIN" 
  }
}

resource "local_file" "DEBUG_BOOTSTRAP_SCRIPT_VAR_NAME" {
  # For inspecting the rendered powershell script as it is loaded onto endpoint through custom_data extension
  content = data.template_file.PS_TEMPLATE_VAR_NAME.rendered
  filename = "${path.module}/output/bootstrap-${var.ENDPOINT_HOSTNAME_VAR_NAME}.ps1"
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

  network_interface_ids         = [
    azurerm_network_interface.AZURERM_NETWORK_INTERFACE_VAR_NAME.id,
  ]

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "19h1-pro"
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
      content      = file("${path.module}/files/FirstLogonCommands.xml")
      setting = "FirstLogonCommands"
  }

  depends_on = [azurerm_network_interface.AZURERM_NETWORK_INTERFACE_VAR_NAME]
}

resource "local_file" "HOSTS_CFG_VAR_NAME" {
  content = templatefile("${path.module}/files/hosts.tpl",
    {
      ip    = azurerm_public_ip.AZURERM_PUBLIC_IP_VAR_NAME.ip_address
      auser = var.ADMIN_USERNAME_VAR_NAME
      apwd  = var.ADMIN_PASSWORD_VAR_NAME
    }
  )
  filename = "${path.module}/hosts-${var.ENDPOINT_HOSTNAME_VAR_NAME}.cfg"
}

resource "null_resource" "VCONFIG_UPLOAD" {

  ## Run this module if var.install_agent boolean is true
  count = INSTALL_AGENT ? 1 : 0

  provisioner "local-exec" {
    command = "sleep 60"
  }

  ### upload velociraptor client config
  provisioner "file" {
    source      = "${path.module}/files/Velociraptor.config.yaml"
    destination = "C:/Program Files/Velociraptor/Velociraptor.config.yaml"
    connection {
      host     = azurerm_public_ip.AZURERM_PUBLIC_IP_VAR_NAME.ip_address
      type     = "winrm"
      user     = var.ADMIN_USERNAME_VAR_NAME
      password = var.ADMIN_PASSWORD_VAR_NAME
      timeout  = "15m"
      https    = true
      port     = "5986"
      insecure = true
    }
  }
depends_on = [azurerm_windows_virtual_machine.AZURERM_WINDOWS_VIRTUAL_MACHINE_VAR_NAME]
}

'''
    return template


def get_main_template():
    template = '''

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=2.94.0"
    }
  }
}

provider "azurerm" {
  features {}
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
  allow_blob_public_access = true

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

output "storage_container" {
  value   = var.storage_container_name
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

# This is the src_ip for white listing Azure NSGs
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
    source_address_prefix      = var.src_ip 
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
    source_address_prefix      = var.src_ip 
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
    source_address_prefix      = var.src_ip 
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-ssh"
    description                = "Allow SSH (SSH-In)"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.src_ip 
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-HTTPS"
    description                = "Permit HTTPS (HTTPS-In)"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.src_ip
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-Spark"
    description                = "Permit Spark (Spark-In)"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = var.src_ip
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-KQL"
    description                = "Permit KQL (KQL-In)"
    priority                   = 106
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8088"
    source_address_prefix      = var.src_ip
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow-Zookeeper"
    description                = "Permit Zookeeper (Zookeeper-In)"
    priority                   = 107
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2181"
    source_address_prefix      = var.src_ip
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-HTTPS-8889"
    description                = "Permit HTTPS Port 8889 (HTTPS-In)"
    priority                   = 108
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8889"
    source_address_prefix      = var.src_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-agent"
    description                = "Permit Agent (8000-In)"
    priority                   = 109
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000"
    source_address_prefix      = var.src_ip
    destination_address_prefix = "*"
  }

  depends_on = [azurerm_resource_group.network]
}
'''
    return template
### END NSG TEMPLATE

# Get the endpoint.tf template
endpoint_template = get_endpoint_template()

# Get the main.tf template
main_template = get_main_template()

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

# replace the var.src_ip string 
nsg_string = default_nsg_template.replace("SRC_PREFIX_VALUE", whitelist_nsg)

# Write the nsg.tf
n = nsg_text_file.write(nsg_string)
print("[+] Creating the nsg terraform file: ",tnsg_file)
logging.info('[+] Creating the nsg terraform file: %s', tnsg_file)
nsg_text_file.close()

#### Beginning of build the Windows 10 Pro systems
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
    #admin_username = config_win10_endpoint['admin_username']
    admin_username = default_admin_username 
    print("    [+] Administrator Username:",admin_username) 
    logging.info('[+] Administrator Username: %s', admin_username)
    #admin_password = config_win10_endpoint['admin_password']
    admin_password = default_admin_password 
    print("    [+] Administrator Password:",admin_password) 
    logging.info('[+] Administrator Password: %s', admin_password)
    join_domain = config_win10_endpoint['join_domain'].lower()
    print("    [+] Join Domain:", join_domain) 
    logging.info('[+] Join Domain: %s', join_domain)
    auto_logon_domain_user = config_win10_endpoint['auto_logon_domain_user']
    print("    [+] Auto Logon Domain User:", auto_logon_domain_user) 
    logging.info('[+] Auto Logon Domain User: %s', auto_logon_domain_user)
    install_sysmon = config_win10_endpoint['install_sysmon']
    print("    [+] Install Sysmon:", install_sysmon) 
    logging.info('[+] Install Sysmon: %s', install_sysmon)
    install_art = config_win10_endpoint['install_art']
    print("    [+] Install Atomic Red Team (ART):", install_art) 
    logging.info('[+] Install Atomic Red Team (ART): %s', install_art)
    if install_agent:
        print("    [+] Forwarding winlogbeat logs to",helk_ip) 
        logging.info('[+] Forwarding winlogbeat logs to: %s', helk_ip)
    if install_agent:
        print("    [+] Installing velociraptor and registering to",helk_ip) 
        logging.info('[+] Installing velociraptor and registering to: %s', helk_ip)
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

        # replace the velociraptor config upload line 
        new_endpoint_template = new_endpoint_template.replace("VCONFIG_UPLOAD", "velociraptor-config_upload" + str(num_suffix))

        # If auto_logon_domain_user is True, get the default ad user and password
        if auto_logon_domain_user.lower() == 'true':
            print("    [+] Auto Logon Domain user")
            logging.info('[+] Auto Logon Domain user')
            print("      [+] Getting the default ad user and password")
            logging.info('[+] Getting the default ad user and password')

            user_dict = random.choice(all_ad_users)
            full_name = user_dict['name']
            password = user_dict['pass']
            names = full_name.split(' ') 
            first = names[0] 
            last = names[1] 
            username = first.lower() + last.lower()
            print("      [+] Auto Logon this Win10 Pro to AD User: ", full_name)
            logging.info('[+] Auto Logon this Win10 Pro to AD User: %s', full_name)
            print("      [+] Username: ",username)
            logging.info('[+] Username: %s', username)
            print("      [+] Password: ",password)
            logging.info('[+] Password: %s', password)

            # replace the AD USER for auto logon 
            new_endpoint_template = new_endpoint_template.replace("ENDPOINT_AD_USER", username)
            # replace the AD PASSWORD for auto logon 
            new_endpoint_template = new_endpoint_template.replace("ENDPOINT_AD_PASSWORD", password)

        # replace the variable admin_username 
        new_endpoint_template = new_endpoint_template.replace("ADMIN_USERNAME_VAR_NAME", "admin-username-" + this_hostname)
        new_endpoint_template = new_endpoint_template.replace("ADMIN_USERNAME_DEFAULT", admin_username)

        # replace the variable admin_password 
        new_endpoint_template = new_endpoint_template.replace("ADMIN_PASSWORD_VAR_NAME", "admin-password-" + this_hostname)
        new_endpoint_template = new_endpoint_template.replace("ADMIN_PASSWORD_DEFAULT", admin_password)

        # replace the variable join_domain for this Windows 10 Pro 
        new_endpoint_template = new_endpoint_template.replace("JOIN_DOMAIN_VAR_NAME", "join-domain-" + this_hostname)
        new_endpoint_template = new_endpoint_template.replace("JOIN_DOMAIN_DEFAULT", join_domain)

        # replace the variable endpoint_hostname for this Windows 10 Pro 
        new_endpoint_template = new_endpoint_template.replace("ENDPOINT_HOSTNAME_VAR_NAME", "endpoint_hostname-" + this_hostname)
        new_endpoint_template = new_endpoint_template.replace("ENDPOINT_HOSTNAME_DEFAULT", this_hostname)

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

        # replace install_agent if applicable
        if install_agent:
            new_endpoint_template = new_endpoint_template.replace("INSTALL_AGENT", "true")
            new_endpoint_template = new_endpoint_template.replace("HELK_IP", helk_ip)
        else:
            new_endpoint_template = new_endpoint_template.replace("INSTALL_AGENT", "false")
            new_endpoint_template = new_endpoint_template.replace("HELK_IP", "")

        # replace install_sysmon if applicable
        if install_sysmon:
            new_endpoint_template = new_endpoint_template.replace("INSTALL_SYSMON", "true")
        else:
            new_endpoint_template = new_endpoint_template.replace("INSTALL_SYSMON", "false")

        # replace install_art if applicable
        if install_art:
            new_endpoint_template = new_endpoint_template.replace("INSTALL_ART", "true")
        else:
            new_endpoint_template = new_endpoint_template.replace("INSTALL_ART", "false")

        # replace DC_IP WinRM, AD Domain if applicable
        if args.dc_enable and config_win10_endpoint['join_domain'].lower() == 'true':
            new_endpoint_template = new_endpoint_template.replace("DC_IP", dc_ip)
            print("    [+] Setting Domain Controller for this endpoint to join domain: ",dc_ip)
            logging.info('[+] Setting Domain Controller fore this endpoint to join domain: %s', dc_ip)

            # Replace WinRM Username
            new_endpoint_template = new_endpoint_template.replace("WINRM_USERNAME", default_winrm_username)

            # Replace WinRM Password
            new_endpoint_template = new_endpoint_template.replace("WINRM_PASSWORD", default_winrm_password)

            # Replace the AD Domain 
            new_endpoint_template = new_endpoint_template.replace("AD_DOMAIN", default_domain)
        else:
            # Replace the Default Domain in locals, for AWS domain configuration for non-domain joined 
            new_endpoint_template = new_endpoint_template.replace("DEFAULT_DOMAIN", default_domain)

        # evaluate the auto_logon setting - This controls whether the domain user is set to automatically logon with domain creds
        if config_win10_endpoint['auto_logon_domain_user'].lower() == "true": 
            new_endpoint_template = new_endpoint_template.replace("AUTO_LOGON_SETTING", "true")
        else:
            new_endpoint_template = new_endpoint_template.replace("AUTO_LOGON_SETTING", "false")

        this_file = this_hostname + ".tf"
        endpoint_text_file = open(this_file, "w")
        n = endpoint_text_file.write(new_endpoint_template)
        print("    [+] Created terraform:", this_file )
        logging.info('[+] Created terraform: %s', this_file)
        endpoint_text_file.close()

        #increment the last octet for each new Win10 Pro
        last_octet_int+=1
### End of build the Windows 10 Pro systems

### BEGIN DOMAIN CONTROLLER CONFIGURATION
def get_dc_template():
    template = '''

locals {
  import_command       = "Import-Module ADDSDeployment"
  password_command     = "$password = ConvertTo-SecureString 'ADMIN_PASSWORD' -AsPlainText -Force"
  install_ad_command   = "Add-WindowsFeature -name ad-domain-services -IncludeManagementTools"
  configure_ad_command = "Install-ADDSForest -DomainName 'DEFAULT_DOMAIN' -InstallDns -SafeModeAdministratorPassword $password -Force:$true"
  shutdown_command   = "shutdown -r -t 10"
  exit_code_hack     = "exit 0"
  powershell_command = "${local.import_command}; ${local.password_command}; ${local.install_ad_command}; ${local.configure_ad_command}; ${local.shutdown_command}; ${local.exit_code_hack}"
}

resource "azurerm_public_ip" "dc1-external" {
  name                     = "dc1-public-ip-${random_string.suffix.id}"
  location                = var.location
  resource_group_name = "${var.resource_group_name}-${random_string.suffix.id}"
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30

  depends_on = [azurerm_resource_group.network]
}

resource "azurerm_network_interface" "dc1-nic-int" {
  name                    = "dc1-int-nic-${random_string.suffix.id}"
  location                = var.location
  resource_group_name = "${var.resource_group_name}-${random_string.suffix.id}"
  internal_dns_name_label = local.virtual_machine_name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.AD_SUBNET_NAME-subnet.id
    private_ip_address_allocation = "static"
    private_ip_address            = "DC_IP_ADDRESS" 
    public_ip_address_id          = azurerm_public_ip.dc1-external.id
  }
  depends_on = [azurerm_resource_group.network]
}

locals {
  virtual_machine_name = "dc1"
  virtual_machine_fqdn = "${local.virtual_machine_name}.DEFAULT_DOMAIN"
  custom_data_params   = "Param($RemoteHostName = \\"${local.virtual_machine_fqdn}\\", $ComputerName = \\"${local.virtual_machine_name}\\")"
  custom_data         = base64encode(join(" ", [local.custom_data_params, data.template_file.ps_template.rendered ]))

}

data "template_file" "ps_template" {
  template = file("${path.module}/files/bootstrap-dc.ps1")

  vars  = {
    winrm_username            = "WINRM_USERNAME" 
    winrm_password            = "WINRM_PASSWORD" 
    admin_username            = "ADMIN_USERNAME" 
    admin_password            = "ADMIN_PASSWORD" 
    ad_domain                 = "DEFAULT_DOMAIN" 
    storage_acct              = "purplecloud${random_string.suffix.id}"
    storage_container	      = var.storage_container_name
    users_file                = var.azure_users_file
  }
}

resource "local_file" "debug_bootstrap_script" {
  # For inspecting the rendered powershell script as it is loaded onto endpoint through custom_data extension
  content = data.template_file.ps_template.rendered
  filename = "${path.module}/output/bootstrap-dc1.ps1"
}


resource "azurerm_windows_virtual_machine" "domain-controller" {
  name                          = local.virtual_machine_name
  location                      = var.location
  resource_group_name = "${var.resource_group_name}-${random_string.suffix.id}"
  size                       = "SIZE_DC"
  computer_name  = local.virtual_machine_name
  admin_username = "ADMIN_USERNAME" 
  admin_password = "ADMIN_PASSWORD" 
  custom_data    = local.custom_data

  network_interface_ids         = [
    azurerm_network_interface.dc1-nic-int.id,
  ]

  os_disk {
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  additional_unattend_content {
      #content      = "<AutoLogon><Password><Value>${var.admin_password}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.admin_username}</Username></AutoLogon>"
      content      = "<AutoLogon><Password><Value>ADMIN_PASSWORD</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>ADMIN_USERNAME</Username></AutoLogon>"
      setting = "AutoLogon"
  }

  additional_unattend_content {
      content      = file("${path.module}/files/FirstLogonCommands.xml")
      setting = "FirstLogonCommands"
  }

  depends_on = [azurerm_resource_group.network]
}

resource "azurerm_virtual_machine_extension" "create-ad-forest" {
  name                 = "create-active-directory-forest"
  virtual_machine_id   = azurerm_windows_virtual_machine.domain-controller.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"
  settings = <<SETTINGS
  {
    "commandToExecute": "powershell.exe -Command \\"${local.powershell_command}\\""
  }
SETTINGS
}

resource "local_file" "hosts_cfg" {
  content = templatefile("${path.module}/templates/hosts-dc.tpl",
    {
      ip    = azurerm_public_ip.dc1-external.ip_address
      auser = "ADMIN_USERNAME" 
      apwd  = "ADMIN_PASSWORD" 
    }
  )
  filename = "${path.module}/hosts-dc.cfg"

}

# Upload the ad_users.csv to the storage account
resource "azurerm_storage_blob" "users_csv" {
  name                   = "ad_users.csv"
  storage_account_name   = azurerm_storage_account.storage-account.name
  storage_container_name = azurerm_storage_container.storage-container.name
  type                   = "Block"
  source                 = "ad_users.csv"
}

'''
    return template

### BEGIN HUNTING ELK + VELOCIRAPTOR CONFIGURATION
def get_helk_template():

    template = '''
resource "azurerm_public_ip" "vh-external" {
  name                    = "vh-public-ip-${random_string.suffix.id}"
  location                = var.location
  resource_group_name = "${var.resource_group_name}-${random_string.suffix.id}"
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30

  depends_on = [azurerm_resource_group.network]
}

resource "azurerm_network_interface" "vh-nic-int" {
  name                    = "vh-nic-int-${random_string.suffix.id}"
  location                = var.location
  resource_group_name = "${var.resource_group_name}-${random_string.suffix.id}"
  internal_dns_name_label = local.virtual_machine_name_helk

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.SIEM_SUBNET_NAME-subnet.id
    private_ip_address_allocation = "static"
    private_ip_address            = "VH_PRIVATE_IP" 
    public_ip_address_id          = azurerm_public_ip.vh-external.id
  }

  depends_on = [azurerm_resource_group.network]
}

locals {
  virtual_machine_name_helk = "velocihelk"
}

# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
    algorithm = "RSA"
    rsa_bits = 4096
}

# Enable if you want to see the SSH key - It is written to a file
output "tls_private_key" { 
  value = tls_private_key.example_ssh.private_key_pem
  sensitive = true
}

data "template_file" "linux-vm-cloud-init" {
  template = file("${path.module}/files/helk.sh.tpl")

  vars = {
   helk_ip = "VH_PRIVATE_IP"
  }
}

resource "azurerm_linux_virtual_machine" "vh_vm" {
  name                          = local.virtual_machine_name_helk
  location                      = var.location
  resource_group_name = "${var.resource_group_name}-${random_string.suffix.id}"
  network_interface_ids         = [azurerm_network_interface.vh-nic-int.id]
  size                       = "SIZE_HELK"
  admin_username		= "helk"
  disable_password_authentication = true

  custom_data = base64encode(data.template_file.linux-vm-cloud-init.rendered)

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name              = "${local.virtual_machine_name}-disk1"
    caching           = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb	= 100
  }

  admin_ssh_key {
    username       = "helk"
    public_key     = tls_private_key.example_ssh.public_key_openssh
  }


  tags = {
    environment = "Velociraptor HELK Prod"
  }

  depends_on = [azurerm_resource_group.network]
}

# write public IP address of Linux host to file
resource "local_file" "hosts_cfg_velociraptor" {
    content = templatefile("${path.module}/templates/hosts.tpl",
        {
        ip = azurerm_public_ip.vh-external.ip_address
        huser = "helk"
        }
    )
    filename = "${path.module}/hosts.cfg"

}

# write ssh key to file
resource "local_file" "ssh_key" {
    content = tls_private_key.example_ssh.private_key_pem
    filename = "${path.module}/ssh_key.pem"
    file_permission = "0700"
}

resource "null_resource" "helk-scp-velociraptor-config" {
  
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
  command = "scp -o StrictHostKeyChecking=no -i ${path.module}/ssh_key.pem helk@${azurerm_public_ip.vh-external.ip_address}:/home/helk/config.yaml ${path.module}/files/Velociraptor.config.yaml"
}
  depends_on = [azurerm_linux_virtual_machine.vh_vm]
}

'''
    return template
### END HUNTING ELK + VELOCIRAPTOR CONFIGURATION

if args.helk_enable:
    # open the helk.tf
    helk_text_file = open(thelk_file, "w")

    # get the helk template
    default_helk_template = get_helk_template()

    # replace to the correct subnet 
    helk_string = default_helk_template.replace("SIEM_SUBNET_NAME", siem_subnet_name)

    # replace to the correct helk_ip 
    helk_string = helk_string.replace("VH_PRIVATE_IP", helk_ip)
  
    # replace the Helk instance size 
    helk_string = helk_string.replace("SIZE_HELK", size_helk)

    # Write the helk.tf
    print("[+] Creating the helk terraform file: ",thelk_file)
    logging.info('[+] Creating the helk terraform file: %s', thelk_file)
    n = helk_text_file.write(helk_string)
    helk_text_file.close()

# Check if dc is enabled
if args.dc_enable:

    # open the dc.tf
    dc_text_file = open(tdc_file, "w")

    # get the helk template
    default_dc_template = get_dc_template()

    # replace with AD subnet 
    dc_string = default_dc_template.replace("AD_SUBNET_NAME", ad_subnet_name)

    # replace with DC IP Address
    dc_string = dc_string.replace("DC_IP_ADDRESS", dc_ip)

    # replace with default domain for AD 
    dc_string = dc_string.replace("DEFAULT_DOMAIN", default_domain)

    # replace with WinRM Username 
    dc_string = dc_string.replace("WINRM_USERNAME", default_winrm_username)

    # replace with WinRM Password 
    dc_string = dc_string.replace("WINRM_PASSWORD", default_winrm_password)

    # replace with local Admin Username 
    dc_string = dc_string.replace("ADMIN_USERNAME", default_admin_username)

    # replace with local Admin Password 
    dc_string = dc_string.replace("ADMIN_PASSWORD", default_admin_password)
  
    # replace the DC instance size 
    dc_string = dc_string.replace("SIZE_DC", size_dc)

    # Write the dc.tf
    print("[+] Creating the dc terraform file: ",tdc_file)
    logging.info('[+] Creating the dc terraform file: %s', tdc_file)
    n = dc_text_file.write(dc_string)
    dc_text_file.close()

    # Change the bootstrap script to import AD users
    ad_bootstrap_template = open("files/bootstrap-dc-template.ps1")

    # Read the script into data
    data = ad_bootstrap_template.read()

    # define an ADUsers array
    new_ad_users = '''
  # The AD users collection / array
  $ADUsers = @()

'''
    # Open up the ad users csv file
    print("[+] Creating users file with %s users: %s" % (len(all_ad_users), ad_users_csv))
    logging.info('[+] Creating users file with %s users: %s', len(all_ad_users), ad_users_csv)

    # open the ad users csv file
    ad_csv = open(ad_users_csv, 'w')

    # Create and write the first line of csv
    line = "name,upn,password,groups,oupath,domain_admin"
    ad_csv.write(line + '\n')

    # loop through the default_ad_users
    for user in default_ad_users:
        full_name = user['name'].split(' ')
        first = full_name[0]
        last = full_name[1]
        usernm = first.lower() + last.lower()
        ou = user['ou']
        password = user['password']
        domain_admin = user['domain_admin']
        groups = user['groups']
        
        # Create line to write users csv
        ou_split = default_domain.split('.')
        if domain_admin.lower() != 'true':
            domain_admin = "False" 
        upn = usernm + "@" + default_domain
        oupath = "OU=" + groups + ";" + "DC=" + ou_split[0] + ";DC=" + ou_split[1]
        line = user['name'] + "," + upn + "," + password + "," + groups + "," + oupath + "," + domain_admin + '\n'
        ad_csv.write(line)

        ad_user_string = "" 

        user_line = '  $ADUsers += (@{FirstName = "%s"; LastName = "%s"; usernm = "%s"; ou = "%s"; pcred = "%s"; groups = "%s"; domain_admin = "%s"})' % (first, last, usernm, ou, password, groups, domain_admin)

        ad_user_string += user_line
        new_ad_users += ad_user_string
        new_ad_users += '\n\n'

    # Loop through the extra_users_list
    for user in extra_users_list:
        full_name = user.split(' ')
        first = full_name[0]
        last = full_name[1]
        usernm = first.lower() + last.lower()
        password = default_aduser_password 
        domain_admin = "" 
        groups = random.choice(ad_groups)

        # Create line to write users csv
        ou_split = default_domain.split('.')
        domain_admin = "False"
        upn = usernm + "@" + default_domain
        oupath = "OU=" + groups + ";" + "DC=" + ou_split[0] + ";DC=" + ou_split[1]
        line = user + "," + upn + "," + password + "," + groups + "," + oupath + "," + domain_admin + '\n'
        ad_csv.write(line)

    # new dc bootstrap script
    new_text_file = open("files/bootstrap-dc.ps1", "w")

    n = new_text_file.write(data)

    new_text_file.close() 

###
# End of dc.tf creation 
###

print("[+] Default Local Administrator Credentials on all Windows")
logging.info('[+] Default Local Administrator Credentials on all Windows')
print("  [+] Username: ", default_admin_username)
logging.info('[+] Username: %s', default_admin_username)
print("  [+] Password: ", default_admin_password)
logging.info('[+] Password: %s', default_admin_password)
if args.ad_domain and args.dc_enable:
    default_domain = args.ad_domain
    print("[+] Built AD DS Domain:",default_domain)
    logging.info('[+] Built AD DS Domain: %s', default_domain)
