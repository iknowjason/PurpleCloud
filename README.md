# Recent Valentine's Day Changes:  2/14/22 
PurpleCloud has changed!  Introducing a Terraform generator using python.  Instead of offering terraform templates that have to be manually edited, the starting point is a Python terraform generator.  The python scripts will create your own custom terraform files based on user input.  The old terraform templates files have been moved to the archive directory.

# Overview
Identity Range supporting Azure AD and Active Directory enterprise deployment with SIEM in Azure.  Easily build your own Pentest / Red Team / Cyber Range in Azure cloud.  PurpleCloud was created as a platform for researching Azure Identity.

# Generating an Azure AD Range using azure_ad.py

## Usage Example:  Generate a basic Azure AD Range 

```$ python3 azure_ad.py --upn rtcfingroup.com```

**Description:** 
This will generate an Azure AD range with a UPN suffix of 'rtcfingroup.com' with 100 users. It will output three files.   The Azure AD password for all users will be automatically generated and output after terraform apply.

* **azure_users.csv**
* **azure_usernames.txt**
* **azure_emails.txt**

## Usage Example:  Generate a range with 1,000 users 
```$ python3 azure_ad.py --upn rtcfingroup.com --count 1000```

**Description:** 
Same as above, except generate 1,000 users in Azure AD.  Running terraform apply will generate a random password shared by all users.

## Usage Example:  Generate a range with Azure applications and groups
```$ python3 azure_ad.py --upn rtcfingroup.com --count 500 --apps 3 --groups 5```

**Description:**
Same as above, except generate 500 users in Azure AD.  Create 3 Azure applications and 5 groups.  Automatically put the 500 users into separate groups. 


# Generating an Azure infrastructure range using azure.py 

## Usage Example:  Generate a single Windows 10 Endpoint with Sysmon installed

```$ python3 azure.py --endpoint 1```

**Description:**
This will generate a single Windows 10 Endpoint and generate a random, unique password with a default local Administrator account named 'RTCAdmin'.  This generates four terraform files - main.tf, network.tf, nsg.tf, and win10-1.tf.

## Usage Example:  Build a Domain Controller with Forest and Users + Windows Domain Join 

```$ python3 azure.py --domain_controller --ad_domain rtcfingroup.com --admin Administrator --password MyPassword012345 --ad_users 500 --endpoints 2```

**Description:**
This will create a Domain Controller in dc.tf and install AD DS with forest name of rtcfingroup.com.  This will create a custom local administrator account and password with 500 domain users.  The domain users will be written to ad_users.csv and will have the password specified in --password.  Note that domain join is disabled by default for Windows 10 Pro.  To enable it you must edit the python script and find the config_win10_endpoint dictionary. Edit 'join_domain' and set the value to true.  This will create two Windows 10 Pro endpoints and automatically join them to the domain.

## Usage Example:  Build a Hunting ELK server and automatically export sysmon winlog beat logs 

```$ python3 azure.py --helk --endpoint 1```

**Description:**
This will add a Hunting ELK server with one Windows 10 Endpoint.  The winlogbeat agent will be installed on Windows 10 Pro and the logs will be sent to the HELK server.  Velociraptor will be installed on the HELK server and the Velociraptor agent on Windows 10 Pro.  The endpoint will automatically register to the Velociraptor server running on HELK.

## Full Usage and Other Details for Advanced Usage:  Azure.py
```--resource_group <rg_name>```:  Name of the Azure resource group to automatically create  (Default:  PurpleCloud)

```--location <location>```:  The Azure location to use (Default:  centralus)

```--endpoints <num_of_endpoints>```:  Number of Windows 10 Professional systems to build (Default: 0)

```--helk```:  Create a hunting ELK server (with Velociraptor installed) (Default:  Disabled)

```--domain_controller```:  Create a Domain Controller and install AD DS with Forest (Default:  Disabled)

```--ad_domain <domain>```:  The name of the AD Domain to provision (Default:  rtc.local)

```--ad_users <num_of_domain_users>```:  The number of AD users to automatically build (Default:  Disabled)

```--admin <admin_username>```:  The Local Administrator account (Default:  RTCAdmin)

```--password <password>```:  The local Administrator password and default AD user password (Default:  auto generate a strong password) 

## Other Options to Manually Edit in azure.py

These are located in the ```config_win10_endpoints``` dictionary:

```hostname_base:```  The base Windows 10 hostname (Default: win10)

```join_domain:```  Whether to join the Windows 10 Pro to the AD Domain.  This is disabled by default.  So if you add a DC you must set this to true to have the systems join to the domain.

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

# Getting Started

## Pre-Requisites

* **Python:**  Tested version:  3.8.10

* **Terraform:**  Tested version:  1.1.2

* **Azure account with subscription:**  https://portal.azure.com
 
## Installing 

1. Clone this repository

2. Install the python faker using pip.  This is a dependency of both python scripts to generate users.

```$ pip3 install faker```

3. Create an Azure Service Principal with the correct permissions and add the four environment variables to your local shell using .env or .envrc:

```
export ARM_SUBSCRIPTION_ID="YOUR_SERVICE_PRINCIPAL_VALUES"
export ARM_TENANT_ID="YOUR_SERVICE_PRINCIPAL_VALUES"
export ARM_CLIENT_ID="YOUR_SERVICE_PRINCIPAL_VALUES"
export ARM_CLIENT_SECRET="YOUR_SERVICE_PRINCIPAL_VALUES"
```

4. Run terraform 
```
terraform init
terraform plan run.plan
terraform apply run.plan
```

# Network Diagram 

![](images/pce.png)

# Use Cases
* Research and pentest lab for Azure AD and Azure Domain Services
* Security testing of Hybrid Join and Azure AD Joined devices
* EDR Testing lab
* PoC / Product Security Lab
* Enterprise Active Directory lab with domain joined devices
* Malware / reverse engineering to study artifacts against domain joined devices
* SIEM / Threat Hunting / DFIR / Live Response lab with HELK + Velociraptor [1, 2]
* Log aggregator architecture to forward logs to a cloud native SIEM (Azure Sentinel)
* Data Science research with HELK server, Jupyter notebooks
* Detection Engineering research with Mordor [3, 4]

 
# Documentation
Please see the full documentation for details and getting started with installation.  

