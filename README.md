![](https://badgen.net/badge/icon/azure?icon=azure&label=platform)

# Documentation
Terraform code generator to create different Azure security labs.

For full documentation visit:  https://www.purplecloud.network

# Changelog

## 9/2/22:  Added support for custom CSV files for loading your own AD users, groups, and OUs into AD DS!
- Import your own CSV file with ```--csv file.csv```.  Must confirm with a specific format that will be documented soon.
- Supported for both ```sentinel.py``` and ```ad.py``` AD DS code generators.

## 9/1/22:  Removed local-exec and ansible! Customizable files!  Upgraded Sysmon and Velociraptor!
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

