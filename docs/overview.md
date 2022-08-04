# Overview

Identity lab supporting Azure AD and Active Directory enterprise deployment with SIEM in Azure. Easily build your own Pentest / Red Team / Cyber Range in Azure cloud. PurpleCloud was created as a platform for researching Azure Identity. This repository contains python scripts that function as Terraform code generators for different use cases.

## azure_ad.py
Generate the terraform for a custom Azure AD security lab. It uses a python library (faker) to generate as many Azure AD users as you desire, also creating AD Groups and AD Applications.  Contains a vulnerable privilege escalation scenario that can be optionally enabled.

## ad.py
Create an Active Directory on-premise environment simulated with Azure VMs. This script is used to generate a more traditional infrastructure range. It can create an Active Directory Domain Services range, generating as many AD users as you wish. It also supports many other features such as Domain Join of Windows 10 systems, in addition to a SIEM instrumented with Sysmon.

## sentinel.py
Create an Azure Sentinel deployment configured in a log analytics workspace.  Optionally configure Windows 10 to ship security and Sysmon logs to Sentinel.  Optionally configure an Active Diretory environment with Domain Join. 

## storage.py
Create some Azure storage resources, including a storage account, containers, blobs, file shares with files, key vault with secrets, keys, and certificate.

## managed_identity.py
Create an Azure managed identity attack lab with an Azure VM, a user or system assigned identity for the VM, and some storage and key vault resources to practice with. 

## phishing_app.py
Create a multi-tenant Azure AD application that can be used for app consent phishing simulations.  You can specify a custom display name for the app along with custom redirect_uri, homepage_url, and logout_url.  

## Use Cases
* Research and pentest lab for Azure AD
* Security testing of Hybrid Join and Azure AD Joined devices
* EDR Testing lab
* PoC / Product Security Lab
* Enterprise Active Directory lab with domain joined devices
* Malware / reverse engineering to study artifacts against domain joined devices
* SIEM / Threat Hunting / DFIR / Live Response lab with HELK + Velociraptor [1, 2]
* Log aggregator architecture to forward logs to a cloud native SIEM (Azure Sentinel)
* Data Science research with HELK server, Jupyter notebooks
* Detection Engineering research with Mordor [3, 4]
