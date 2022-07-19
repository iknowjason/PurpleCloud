# Usage

## Azure Active Directory lab

Generating an Azure AD lab using ```azure_ad.py```.

This generates terraform formatted HCL files for ```users.tf```.  If applications and groups are created, the ```apps.tf``` and ```groups.tf``` will also be created.

### Generate a basic Azure AD lab

Usage Example:  Generate a basic Azure AD lab

```$ python3 azure_ad.py --upn rtcfingroup.com```

**Description:** 
This will generate an Azure AD range with a UPN suffix of ```rtcfingroup.com``` with 100 users. It will output three files.   The Azure AD password for all users will be automatically generated and output after terraform apply.

* **azure_users.csv:** A csv including the Azure AD user's full name, username, and email address.
* **azure_usernames.txt:**  A file including just the usernames.
* **azure_emails.txt:** A file including just the email addresses.
* **users.tf:** Terraform file that will build the users.

### Generate an Azure AD lab with 1,000 users 

Usage Example:  Generate an Azure AD lab with 1,000 users 

```$ python3 azure_ad.py --upn rtcfingroup.com --count 1000```

**Description:** 
Same as above, except generate 1,000 users in Azure AD.  Running terraform apply will generate a random password shared by all users.  The password applied to all users will be displayed at the end of ```terraform apply```.  To display the passwor again, run ```terraform output```.  


### Generate a lab with Azure applications and groups

Usage Example:  Generate a lab with Azure applications and groups

```$ python3 azure_ad.py --upn rtcfingroup.com --count 500 --apps 3 --groups 5```

**Description:**
Same as above, except generate 500 users in Azure AD.  Create 3 Azure applications and 5 groups.  Automatically put the 500 users into separate groups. 

- **apps.tf:**  A terraform file with the Azure applications.
- **groups.tf:**  A terraform file with the Azure groups.

### Generate a lab for Service Principal abuse attack primitives

Usage Example:  Generate a lab for Service Principal abuse attack primitives

```$ python3 azure_ad.py -c 25 --upn rtcfingroup.com --apps 7 -aa -ga -pra```

**Description:** 
This will generate an Azure AD range with a UPN suffix of ```rtcfingroup.com``` with 25 users. It will add some service principal abuse attack primitives to some random resources.  First, the ```--apps 7``` will add 7 Azure AD applications (App Registrations) with associated Service Principals (Enterprise Applications).  The ```-aa``` flag will assign an Application Administrator role randomly to one of the 25 Azure AD users.  The ```-ga``` flag will assign the Global Administrator role randomly to one of the 7 application SPs.  Finally, the ```-pra``` flag will assign the Privileged role administrator role randomly to one of the other 7 application SPs.

## Azure VMs, Active Directory, and SIEM 

Generating an Azure infrastructure lab using ad.py 

### Generate a single Windows 10 Endpoint with Sysmon installed

Usage Example:  Generate a single Windows 10 Endpoint with Sysmon installed

```$ python3 ad.py --endpoint 1```

**Description:**
This will generate a single Windows 10 Endpoint and generate a random, unique password with a default local Administrator account named 'RTCAdmin'.  This generates four terraform files:
- **main.tf:** Terraform file with resource group and location.
- **network.tf:** Terraform file with VNet and subnets. 
- **nsg.tf:** Terraform file with Network Security Groups.
- **win10-1.tf:** Terraform file with Windows 10 Pro configuration.


### Build a Domain Controller with Forest and Users + Windows Domain Join 

```$ python3 ad.py --domain_controller --ad_domain rtcfingroup.com --admin RTCAdmin --password MyPassword012345 --ad_users 500 --endpoints 2  --domain_join```

**Description:**
This will create a Domain Controller in dc.tf and install AD DS with forest name of rtcfingroup.com.  This will create a custom local administrator account and password with 500 domain users.  The domain users will be written to ad_users.csv and will have the password specified in --password.  Note that domain join is disabled by default for Windows 10 Pro but the ```domain_join``` parameter enables it for all Windows 10 Pro created.  This will also create two Windows 10 Pro terraform files (win10-1.tf, win10-2.tf) as well as a terraform file for the Domain Controller (dc.tf).

### Build a Hunting ELK server and automatically export sysmon winlog beat logs 

```$ python3 ad.py --helk --endpoint 1```

**Description:**
This will add a Hunting ELK server with one Windows 10 Endpoint.  The winlogbeat agent will be installed on Windows 10 Pro and the logs will be sent to the HELK server.  Velociraptor will be installed on the HELK server and the Velociraptor agent on Windows 10 Pro.  The endpoint will automatically register to the Velociraptor server running on HELK.  This will create a terraform file for the HELK server (helk.tf)

### Advanced Usage
```--resource_group <rg_name>```:  Name of the Azure resource group to automatically create  (Default:  PurpleCloud)

```--location <location>```:  The Azure location to use (Default:  centralus)

```--endpoints <num_of_endpoints>```:  Number of Windows 10 Professional systems to build (Default: 0)

```--helk```:  Create a hunting ELK server (with Velociraptor installed) (Default:  Disabled)

```--domain_controller```:  Create a Domain Controller and install AD DS with Forest (Default:  Disabled)

```--ad_domain <domain>```:  The name of the AD Domain to provision (Default:  rtc.local)

```--ad_users <num_of_domain_users>```:  The number of AD users to automatically build (Default:  Disabled)

```--admin <admin_username>```:  The Local Administrator account (Default:  RTCAdmin)

```--password <password>```:  The local Administrator password and default AD user password (Default:  auto generate a strong password) 

```--domain_join```:  Join the Windows 10 Pro systems to the AD Domain (Default:  false)

```--auto_logon```:  Automatically logon the domain user with their credentials upon system start (Default:  false)


### Edit script options in ad.py 

**Windows 10 Pro configuration:**   The Windows 10 Pro default configuration can be adjusted to meet your needs.

These are located in the ```config_win10_endpoints``` dictionary:

```hostname_base:```  The base Windows 10 hostname (Default: win10)

```join_domain:```  Whether to join the Windows 10 Pro to the AD Domain.  This is disabled by default.  So if you add a DC and want to join the Windows 10 Pro systems to the AD Domain, you can set this to true.  Or you can use the command line parameter ```--domain-join```.

```auto_logon_domain_users:```  Configure the endpoint (via registry) to automatically log in the domain user.  This will randomly select an AD user.  Disabled by default and requires domain join and DC.

```install_sysmon:```  Automatically install Sysmon with Swift on Security configuration (Default:  Enabled)

```install_art:```  Install Atomic Red Team (art).  (Default:  Enabled) 


```
config_win10_endpoint = {
    "hostname_base":"win10",
    "join_domain":"false",
    "auto_logon_domain_user":"false",
    "install_sysmon":"true",
    "install_art":"true",
}
```

**Default AD Users:**   There is a python dictionary specifying the default AD users.  This can be changed to suit your needs.  These are the first five users automaticaly created.  After the first five, users are randomly generated to meet the ```--ad_users <number>``` amount.

Here is the default_ad_users list along with the first user, that can be searched for in the file:
```
default_ad_users = [
    {
        "name":"Lars Borgerson",
        "ou": "CN=users,DC=rtc,DC=local",
        "password": get_password(),
        "domain_admin":"",
        "groups":"IT"
    },
```

**Network Subnets configuration:**   The configuration for the subnets can be adjusted in the python list named ```config_subnets```.  Some changes include changing the default subnet names or adding/removing subnets.  By default there are four subnets created.  

**Other Details:**  
* **ranges.log:**  The ranges.log file writes out important information as the range is built, such as VM details.  You can use it to track things.  We are working on adding solid terraform outputs that will be useful too. 

* **Logging Passwords:** By default, all passwords are randomly generated.  So if you are not aware of this, it might be easy to lose track of a password.  For this reason we have added a logging feature that captures all passwords created.  The ```ad.py``` script will automatically log all output to a logfile called ```ranges.log```.  This is for the specific purpose of being able to track the ranges created and the passwords that are auto-generated for AD users and local Administrator accounts. 

* **Azure Network Security Groups:**  By default, the ad.py script will try to auto-detect your public IP address using a request to http://ifconfig.me.  Your public IP address will be used to white list the Azure NSG source prefix setting.  You can over-ride this behavior by changing the ```override_whitelist``` variable to False.  By default it will then use the value set in ```whitelist_nsg```.  This is set to wide open ("*") and you can change this to a static value.

## Azure Sentinel lab 

```$ python3 sentinel.py -n <NAME> -l <LOCATION> -odc -adc```

This generates a terraform format HCL file for ```sentinel.tf``` and ```providers.tf```.

Specify the resource group and name of resources with ```NAME``` and the Azure location wit ```LOCATION```.

```-n <NAME>```:  Specify a resource group name and name for other resources (Default: purplecloud-sentinel)

```-l <LOCATION>```:  Specify a different location (Default: centralus)

```-odc```:  Optionally enables the Office 365 data connector for Sentinel.

```-adc```:  Optionally enables the Azure AD data connector for Sentinel.

## Azure Storage lab 

```$ python3 storage.py -n <NAME> -l <LOCATION>```

Generates a terraform format HCL file for ```storage.tf``` and ```providers.tf```.

This is a great generator for quickly creating a bunch of vulnerable cloud storage resources or studying the different security permission levels.  It also builds an Azure Key Vault resources.

### Resources Created

* Azure Storage Account (1)
* Azure Containers (3)
The containers have three different access levels (Blob, Container, Private)
* Azure Blobs (3).  All three are uploaded to all three containers.
* Azure Shares (2)
* Two files are uploaded to the two shares
* Azure Key Vault
* Secrets (3)
* Private Keys (1)
* Certificates (1) 

### Options

Specify the resource group and name of resources with ```NAME``` and the Azure location wit ```LOCATION```.

```-n <NAME>```:  Specify a resource group name and name for other resources (Default: purplecloud-sentinel)

```-l <LOCATION>```:  Specify a different location (Default: centralus)

## Azure Managed Identity lab 

```$ python3 managed_identity.py -u <UPN_SUFFIX> -n <NAME> -l <LOCATION> -a <ADMIN_USERNAME> -p <PASSWORD> -sa -ua <USER_ASSGNED_IDENTITY>```

Create a security lab for practicing managed identity attack and defense.  Generates a terraform format HCL file for ```managed_identity.tf```,  ```providers.tf```, and ```mi_user.tf```.

### Resources Created 
* One Azure AD User with a configurable Role Assignment (Default:  Virtual Machine Contributor)
* One Azure VM with a Managed Identity configured (Default:  User Assigned Identity with Reader on the Subscription)
* Azure Storage Account (1)
* Azure Containers (3)
The containers have three different access levels (Blob, Container, Private)
* Azure Blobs (3).  All three are uploaded to all three containers.
* Azure Shares (2)
* Two files are uploaded to the two shares
* Azure Key Vault
* Secrets (3)
* Private Keys (1)
* Certificates (1)

### Options

```-u <UPN_SUFFIX>```:  Mandatory.  Specify the correct UPN Suffix for your tenant.  Needed for creating the Azure AD user. 

```-a <ADMIN_USERNAME>```:  Specify the local Administrator Username for the Windows 10 Pro Azure VM. (Default:  MIAdmin)

```-p <PASSWORD>```: Specify the password for the local Administrator account on the VM as well as the Azure AD user (Default:  Auto-generated)

```-sa```: Enables the System Assigned Identity for the Azure VM (Note:  both user assigned and system assigned can be enabled)  

```-ua reader|contributor|owner```: Enables the User Assigned Identity for the Azure VM with possible values of reader, contributor, owner (Default:  reader) 

```-n <NAME>```:  Specify a resource group name and name for other resources

```-l <LOCATION>```:  Specify a different location (Default: centralus)

### Other Variables in Script

```
# This is the src_ip for white listing Azure NSGs
# allow every public IP address by default
variable "src_ip" {
  default = "0.0.0.0/0"
}
``` 

The role of the managed identity by default is scoped to the subscription

```
# Assign the reader role on the Key vault to the Managed Identity
resource "azurerm_role_assignment" "uai" {
  #Scope to the key vault in line below
  #scope                = azurerm_key_vault.example.id
  #Scope to the subscription in line below
  scope                = data.azurerm_subscription.mi.id
  role_definition_name = "ROLE_DEFINITION_NAME"
  principal_id         = azurerm_user_assigned_identity.uai.principal_id
}
```

The role of the Azure AD user
```
# The role scoped to subscription for AAD user
# uncomment as needed
variable "user_role" {
  default = "Virtual Machine Contributor"
  #default = "Contributor"
  #default = "Reader"
  #default = "Owner"
}
```



