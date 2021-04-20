
# Features and Information
* **New Feature:**  Azure Active Directory terraform module:  Deploys Azure Active Directory users, groups, applications, and service principals
* **New Feature:**  Azure Domain Services terraform module:  Deploys Azure AD Domain Services for your managed AD in the Azure cloud
* **New Feature:**  Three tools for Adversary Simulation: Script to automatically invoke Atomic Red Team unit tests using Ansible playbook.
* **New Feature:**  Velociraptor [1] + Hunting ELK [2] System: Windows 10 Endpoints instrumented with agents to auto register Velociraptor and send Sysmon logs
* Pentest adversary Linux VM accessible over RDP
* Deploys one Linux 18.04 HELK Server.  Deploys HELK install option #4, including KAFKA + KSQL + ELK + NGNIX + SPARK + JUPYTER + ELASTALERT
* Windows 10 endpoints with Sysmon (SwiftOnSecurity) and Winlogbeat
* Windows 10 endpoints are automatically configured to use HELK configuration + Kafka Winlogbeat output to send logs to HELK
* Automatically registers the endpoint to the Velociraptor server with TLS self-signed certificate configuration
* Windows endpoint includes Atomic Red Team (ART), Elastic Detection RTA, and APTSimulator
* One (1) Windows 2019 Domain Controller and one (1) Windows 10 Pro Endpoint (with three more that can be easily enabled)
* Automatically joins all Windows 10 computers to the AD Domain (with option to disable Domain Join per machine)
* Uses Terraform templates to automatically deploy in Azure with VMs
* Terraform templates write customizable Ansible Playbook configuration
* Post-deployment Powershell script provisions three domain users on the 2019 Domain Controller and can be customized for many more
* Azure Network Security Groups (NSGs) can whitelist your source prefix (for added security)
* Post-deploy Powershell script that adds registry entries on each Windows 10 Pro endpoint to automatically log in each username into the Domain as respective user.  This feature simulates a real AD environment with workstations with interactive domain logons.  
* Default Modules (Enabled):  One Windows Server, One Windows 10 Endpoint, One Velociraptor + HELK Server
* Extra Modules (Disabled):  One Linux Adversary, Three Windows 10 Endpoints, Azure AD, Azure AD Domain Services
* **Approximate build time:**  16 minutes
