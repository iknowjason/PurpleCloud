# Azure Sentinel lab

## Overview
This tool generates an Azure sentinel lab with optional Windows 10 Endpoints forwarding logs to the Sentinel Log Analytics workspace.  Optionally configure a Domain Controller with Domain Join.  Windows 10 Azure VMs automatically install and configure the legacy Microsoft Monitoring Agent (MMA) or Operations Management Suite (OMS) and send logs to the Log Analytics workspace.  The endpoints will install Sysmon by default. Note that some manual configuration steps are required for final logging configuration.   

## Manual Logging Configuration

After creating the lab there are a couple of manual setup steps required. 

### Step 1:  Add Sysmon Channel in log analytics agents configuration

Navigate into the ```log analytics workspace``` and ```agents configuration```.  Select the ```add windows event log```.  Type ```Microsoft-Windows-Sysmon/Operational``` into the Log name input field and select Apply.  The following screen shot shows how the configuration should look. 

![](./images/sysmon.png)


### Step 2:  Enable the Sentinel Data Connector - "Security Events via Legacy Agent"
Navigate into Sentinel.  Find ```Data connectors``` under ```Configuration```.  In the search field or by scrolling below, find the connector named ```Security Events via Legacy Agent```.  Select ```open the connector page``` in the lower right hand corner.  Select ```Common``` under ```which events to stream``` and ```Apply changes.```  Verify that the connector shows a green highlight and shows connected, as shown below.

![](./images/connector.png)

### Step 3:  Reboot Virtual Machines and Verify connected in Agents Management

Verify that all Windows 10 Virtual machines show as connected.  Verify this by navigating into the ```Log Analytics workspace``` and looking under ```Agents management``` under ```settings```.  Reboot each of the Azure Virtual Machines and then look to verify that they all list a connected status.  It should look like the following screen shot shown below.
  
![](./images/connected.png)

Note: When configuring ```Domain Join``` with Active Directory, the Azure Windows 10 Professional machines will automatically reboot after joining the domain, so no manual reboot is necessary.  

After the Virtual Machines reboot, you can navigate into the Sentinel overview page and start to see new Sysmon and Windows security event logs in the Overview.  The ```Sysmon``` logs will show under ```EVENT``` table while the security event logs will show under the ```SECURITYEVENT``` table.

![](./images/logs.png)

## Usage Examples

### Generate a simple Azure Sentinel lab
 
```$ python3 sentinel.py```

This generates an Azure Sentinel lab with a Log Analytics workspace.

This generates a terraform format HCL file for ```sentinel.tf``` and ```providers.tf```.

```-l <LOCATION>```:  Specify a different location (Default: eastus)

```-odc```:  Optionally enables the Office 365 data connector for Sentinel.

```-adc```:  Optionally enables the Azure AD data connector for Sentinel.

### Generate a single Windows 10 Endpoint with Sysmon installed

Usage Example:  Generate a single Windows 10 Endpoint with Sysmon installed

```$ python3 sentinel.py --endpoint 1```

All Windows 10 Pro systems will automatically send logs to Sentinel.  (Some small, manual configuration steps are required (listed above) to get Sysmon and security logs working correctly).

### Build a Domain Controller with Forest and Users + Windows Domain Join

```$ python3 sentinel.py --domain_controller --ad_domain rtcfingroup.com --admin RTCAdmin --password MyPassword012345 --ad_users 500 --endpoints 2  --domain_join```

**Description:**
This will automatically create an Azure Sentinel deployment.  This will also create a Domain Controller in dc_sentinel.tf and install AD DS with forest name of rtcfingroup.com.  This will create a custom local administrator account and password with 500 domain users.  The domain users will be written to ad_users.csv and will have the password specified in --password.  Note that domain join is disabled by default for Windows 10 Pro but the ```domain_join``` parameter enables it for all Windows 10 Pro created.  This will also create two Windows 10 Pro terraform files (win10-1.tf, win10-2.tf) as well as a terraform file for the Domain Controller (dc_sentinel.tf).  For the two Windows 10 Pro endpoints, they will be configured with the Microsoft Monitoring Agent (MMA) to ship logs to Log Analytics Workspace with Azure Sentinel.

### Advanced Usage
```--resource_group <rg_name>```:  Name of the Azure resource group to automatically create  (Default:  PurpleCloud)

```--location <location>```:  The Azure location to use (Default:  eastus)

```--endpoints <num_of_endpoints>```:  Number of Windows 10 Professional systems to build (Default: 0)

```--domain_controller```:  Create a Domain Controller and install AD DS with Forest (Default:  Disabled)

```--ad_domain <domain>```:  The name of the AD Domain to provision (Default:  rtc.local)

```--ad_users <num_of_domain_users>```:  The number of AD users to automatically build (Default:  Disabled)

```--admin <admin_username>```:  The Local Administrator account (Default:  RTCAdmin)

```--password <password>```:  The local Administrator password and default AD user password (Default:  auto generate a strong password)
```--domain_join```:  Join the Windows 10 Pro systems to the AD Domain (Default:  false)

```--auto_logon```:  Automatically logon the domain user with their credentials upon system start (Default:  false)

### Edit script options in sentinel.py

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
* **ranges.log:**  The ranges.log file writes out important information as the range is built, such as VM details.  You can use it to track things.

* **Logging Passwords:** By default, all passwords are randomly generated.  So if you are not aware of this, it might be easy to lose track of a password.  For this reason we have added a logging feature that captures all passwords created.  The ```sentinel.py``` script will automatically log all output to a logfile called ```ranges.log```.  This is for the specific purpose of being able to track the ranges created and the passwords that are auto-generated for AD users and local Administrator accounts.  You can also type ```terraform output``` as a secondary way to get the password and details for each virtual machine.


* **Azure Network Security Groups:**  By default, the sentinel.py script will try to auto-detect your public IP address using a request to http://ifconfig.me.  Your public IP address will be used to white list the Azure NSG source prefix setting.  You can over-ride this behavior by changing the ```override_whitelist``` variable to False.  By default it will then use the value set in ```whitelist_nsg```.  This is set to wide open ("*") and you can change this to a static value.

### Terraform Outputs
You can get the details of each Virtual Machine, including passwords, by typing ```terraform output```.
