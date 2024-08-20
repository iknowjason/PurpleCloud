![](https://badgen.net/badge/icon/azure?icon=azure&label=platform) ![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/iknowjason/PurpleCloud) ![PyPI - Python Version](https://img.shields.io/pypi/pyversions/faker) ![GitHub repo size](https://img.shields.io/github/repo-size/iknowjason/PurpleCloud)

# Documentation
Terraform code generator to create different Azure security labs.

For full documentation visit:  https://www.purplecloud.network

# Changelog
## 8/20/24:  Updated Azure Sentinel Generator (Detection Engineering Update:  Get endpoint and Entra logs in same LAW)
- On sentinel.py: Updated new Azure Monitor Agent (AMA) automated installation on dc and all windows endpoints!  From now on, all windows endpoints automatically send logs to Log Analytics Workspace / Sentinel.  Updated detection rule filter for Sysmon and Windows / Security event logs.
- On sentinel.py: Added Managed Identity VM attack pathway. 
- On sentinel.py: Added Diagnostic setting automated terraform deployment to send Entra ID logs to Log Analytics Workspace / Sentinel 
- On sentinel.py: On Domain Controller, added Sysmon install and sending all Sysmon/Security logs to LAW/Sentinel 
- On sentinel.py: On Domain Controller, removed CSE and streamlined AD Forest installation through powershell 
- On sentinel.py: Removed Elastic Detection Rules and APT Simulator 

## 2/18/24:  Updated Atomic Red Team (ART) installation 
- On sentinel.py, ad.py:  Updated ART installation to latest method for easy Invoke-Atomics
- On sentinel.py, ad.py:  Fixed installation bug for Elastic Detection Rules

## 11/18/22:  Updated managed_identity.py and aadjoin.py
- On managed_identity.py, changed the default VM size to ```A1v2``` to provide better cost.
- On aadjoin.py, changed the default Azure AD password to remove special characters.

## 11/3/22:  Added new terraform generators:  ADFS & AADJoin
- Added a new Terraform Generator:  adfs.py.  This builds a Federation ADFS lab with a DC.
- Added a new Terraform Generator:  aadjoin.py.  This builds an Azure AD Join lab with Windows 10 managed devices.
- Moves all generators into separate sub-directories for cleaner separation of terraform resources and state, ease of use
- Remove archive directory for older templates
- Drops AAD connect msi on desktop of ADFS server
- Adds PurpleSharp to always download on Windows 10 Pro: ad.py, sentinel.py
- Updated bootstrap scripts to always expand-archive: ad.py, sentinel.py

## 9/8/22:  Updated managed identity generator for automated white listing of source IP.
- Fixed one issue with new directory name for Windows 10
- Changed managed_identity.py to use new automatic white listing using http data resource of ifconfig.me

## 9/6/22:  Updated Azure AD Connect on Domain Controller.
- Customizable Azure AD Connect msi included in ```files/dc``` folder.
- Updates AAD Connect MSI to version 2.x
- Automatic upload/download to DC's local administrator Desktop

## 9/2/22:  Added support for custom CSV files for loading your own AD users, groups, and OUs into AD DS.
- Import your own CSV file with ```--csv file.csv```.  Must conform with a specific format described in ```How AD Builds on the DC``` section
- Supported for both ```sentinel.py``` and ```ad.py``` AD DS code generators.

## 9/1/22:  Removed local-exec and ansible! Customizable files!  Upgraded Sysmon and Velociraptor.
- Removed local-exec and ansible dependencies.  All post configuration management is done with user-data and bash/powershell.
- Changed all files in range (winlogbeat, sysmon, sysmon-config) to be self-contained and customizable for upload to/from a storage container.
- Upgraded Sysmon to v14 and and latest SwiftOnSecurity Sysmon-Config
- Upgraded Velociraptor to v6.5.2

## 8/4/22:  Updated Sentinel Lab for Active Directory Build + Ship Sysmon and Security Logs into Sentinel! 
Build an Azure Sentinel lab with optional support for shipping Windows 10 Sysmon and Security logs into Sentinel Log Analytics Workspace.  Optionally build Active Directory with Domain Join.

## 8/2/22:  Added a new Terraform Generator:  Phishing Application
You can quickly spin up a multi-tenant Azure Ad application to be used for app consent phishing simulations.  It automatically builds typical API consent permissions such as reading email and files, but can be customized for any supported permissions you require.

## 7/18/22:  Added three new Terraform Generators:  Azure Sentinel, Azure Storage, Azure Managed Identity
Create three new security labs for different use cases.  You can quickly spin up an Azure Sentinel security lab, an Azure storage account with file shares, containers, blobs, and sample files.  This also includes an Azure Key Vault with resources.  Or create an Azure managed identity security lab for offensive operations and network defenders.  See the full documentation for more details.

## 5/13/22:  Added Service Principal abuse attack primitives optional support
Added support to dynamically add some Service Principal abuse attack primitives.  This includes dynamically adding an Application Administrator to a random Azure AD user (```-aa```), a Privileged role admin to a random application SP (```-pra```), as well as a Global admin role target to a random application SP (```-ga```).  See the ```azure_ad.py``` usage examples below for more information.  We also added attack scripts for the service principal abuse scenario in ```attack_scripts``` directory.

## 2/14/22:  Valentine's Day Updates:  Python terraform generator
PurpleCloud has changed!  Introducing a Terraform generator using python.  Instead of offering terraform templates that have to be manually edited, the starting point is a Python terraform generator.  The python scripts will create your own custom terraform files based on user input.  The terraform template files have been moved to archive.

