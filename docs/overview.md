# Overview

Identity lab supporting Azure AD and Active Directory enterprise deployment with SIEM in Azure. Easily build your own Pentest / Red Team / Cyber Range in Azure cloud. PurpleCloud was created as a platform for researching Azure Identity. This repository contains python scripts that function as Terraform code generators for different use cases.

## Capabilities and Use Cases

* **Hybrid Identity lab:**  Automatically create a simulated AD on-premise environment with configurable users plus an Azure AD environment with configurable users.  Automatically place the latest Azure AD Connect installer on the DC's desktop.  This can save security researchers a significant amount of time in building Hybrid Identity deployments.

* **Detection Engineering + Purple Teaming:**  Security simulation lab to run attack and defense simulations against a realistic enterprise environment.

* **Azure AD Lab:**  Security lab for learning Azure AD plus running simulations for Red and Blue teams.

* **Active Directory lab:** Simulate an on-premise AD environment using Azure VMs, for learning, training, and Red/Blue team simulations.

* **Sentinel lab:** Supports automated deployment of Microsoft Sentinel for learning, training, and attack/defense simulations.

* **Azure Storage lab:** Creates a deployment with Azure storage blobs, shares, files, and key vaults with secrets, keys, and certificates.

* **Phishing App lab:** Automatically deploy a multi-tenant phishing app for learning, training, and simulations of attack and defense.

* **ADFS Federation lab:** Automatically deploy an ADFS server joined to an AD domain with a DC and optional users and Windows 10 systems.

* **AAD Join:** Creates Windows 10 systems joined to Azure AD, with customizable roles and Azure AD users.

* **Azure AD features:** 
    * Customizable Azure AD Domain 
    * Automatically deploy customizable number of randomly generated Azure AD users
    * Build up to 7 Azure AD applications
    * Build up to 11 Azure AD Groups
    * Auto-assign Azure AD users into groups
    * One optional privilege escalation abuse scenario included + attack scripts

* **Active Directory features:** 
    * Domain Join Windows 10
    * Customizable AD Domain
    * Configurable number of windows 10 endpoints
    * Command line parameters to randomly generate passwords or specify custom password
    * Automatically log on Domain Users into Windows 10 endpoint with domain user creds
    * Automatically add configurable number of AD users, groups, and OUs
    * Import custom AD users, groups, and OUs from user supplied CSV
    * Customizable Azure AD Connect MSI

* **Detection Engineering, SIEM, DFIR:** 
    * Sentinel:  Support for Windows 10 Sentinel automated shipping of Sysmon and Windows Event Logs to Sentinel 
    * Velociraptor Live Response:  Velociraptor 6.5.2:  Server and endpoint instrumentation with internal PKI
    * Hunting ELK automated server deployment and Windows 10 endpoint agent instrumentation to ship logs to server 
    * Customizable Winlogbeat version and configuration
    * Sysmon 14:  Fully customizable sysmon configuration and upgradeable to future Sysmon versions past v14 current support

## Tools

### azure_ad.py
Generate the terraform for a custom Azure AD security lab. It uses a python library (faker) to generate as many Azure AD users as you desire, also creating AD Groups and AD Applications.  Contains a vulnerable privilege escalation scenario that can be optionally enabled.

### ad.py
Create an Active Directory on-premise environment simulated with Azure VMs. This script is used to generate a more traditional infrastructure range. It can create an Active Directory Domain Services range, generating as many AD users as you wish. It also supports many other features such as Domain Join of Windows 10 systems, in addition to a SIEM instrumented with Sysmon.

### sentinel.py
Create a Microsoft Sentinel deployment configured in a log analytics workspace.  Optionally configure Windows 10 to ship security and Sysmon logs to Sentinel.  Optionally configure an Active Diretory environment with Domain Join. 

### storage.py
Create some Azure storage resources, including a storage account, containers, blobs, file shares with files, key vault with secrets, keys, and certificate.

### managed_identity.py
Create an Azure managed identity attack lab with an Azure VM, a user or system assigned identity for the VM, and some storage and key vault resources to practice with. 

### phishing_app.py
Create a multi-tenant Azure AD application that can be used for app consent phishing simulations.  You can specify a custom display name for the app along with custom redirect_uri, homepage_url, and logout_url.  

### adfs.py
Creates an ADFS deployment for Hybrid Federation security research.  The ADFS server can be built with a self-signed certificate or import a trusted, CA signed certificate.  Builds a Domain Controller with optional, additional AD users and Windows 10 Professional systems. 

### aadjoin.py
Creates an Azure AD Join security research lab.  Virtual Machines are joined to Azure AD with Azure AD users that can login over RDP.  An optional User Assigned Identity can be added.

## Use Cases
* Research and pentest lab for Azure AD
* Security testing of Hybrid Join and Azure AD Joined devices
* Federation ADFS lab security research
* EDR Testing lab
* PoC / Product Security Lab
* Enterprise Active Directory lab with domain joined devices
* Malware / reverse engineering to study artifacts against domain joined devices
* SIEM / Threat Hunting / DFIR / Live Response lab with HELK + Velociraptor [1, 2]
* Log aggregator architecture to forward logs to a cloud native SIEM (Microsoft Sentinel)
* Data Science research with HELK server, Jupyter notebooks
* Detection Engineering research with Mordor
