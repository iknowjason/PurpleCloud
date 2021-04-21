## Use Cases
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

## Features and Information
* **New Feature:**  Azure Active Directory terraform module:  Deploys Azure Active Directory users, gr
oups, applications, and service principals
* **New Feature:**  Azure Domain Services terraform module:  Deploys Azure AD Domain Services for your
 managed AD in the Azure cloud
* **New Feature:**  Three tools for Adversary Simulation: Script to automatically invoke Atomic Red Te
am unit tests using Ansible playbook.
* **New Feature:**  Velociraptor [1] + Hunting ELK [2] System: Windows 10 Endpoints instrumented with 
agents to auto register Velociraptor and send Sysmon logs
* Pentest adversary Linux VM accessible over RDP
* Deploys one Linux 18.04 HELK Server.  Deploys HELK install option #4, including KAFKA + KSQL + ELK +
 NGNIX + SPARK + JUPYTER + ELASTALERT
* Windows 10 endpoints with Sysmon (SwiftOnSecurity) and Winlogbeat
* Windows 10 endpoints are automatically configured to use HELK configuration + Kafka Winlogbeat outpu
t to send logs to HELK
* Automatically registers the endpoint to the Velociraptor server with TLS self-signed certificate con
figuration
* Windows endpoint includes Atomic Red Team (ART), Elastic Detection RTA, and APTSimulator
* One (1) Windows 2019 Domain Controller and one (1) Windows 10 Pro Endpoint (with three more that can
 be easily enabled)
* Automatically joins all Windows 10 computers to the AD Domain (with option to disable Domain Join pe
r machine)
* Uses Terraform templates to automatically deploy in Azure with VMs
* Terraform templates write customizable Ansible Playbook configuration
* Post-deployment Powershell script provisions three domain users on the 2019 Domain Controller and ca
n be customized for many more
* Azure Network Security Groups (NSGs) can whitelist your source prefix (for added security)
* Post-deploy Powershell script that adds registry entries on each Windows 10 Pro endpoint to automati
cally log in each username into the Domain as respective user.  This feature simulates a real AD envir
onment with workstations with interactive domain logons.  
* Default Modules (Enabled):  One Windows Server, One Windows 10 Endpoint, One Velociraptor + HELK Ser
ver
* Extra Modules (Disabled):  One Linux Adversary, Three Windows 10 Endpoints, Azure AD, Azure AD Domai
n Services
* **Approximate build time:**  16 minutes

