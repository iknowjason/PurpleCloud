# Azure VMs, Active Directory, and SIEM 

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

```--location <location>```:  The Azure location to use (Default:  eastus)

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
