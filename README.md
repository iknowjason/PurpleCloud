# About JuliaRT
Automated template for building your own pentest/red team/cyber range in the cloud!  JuliaRT is an Active Directory enteprise deployment automated with Terraform / Ansible Playbook templates to be deployed in Azure.
Quick Fun Facts:
* Deploys one (1) Windows 2019 Domain Controller and three (3) Windows 10 Pro Endpoints
* Uses Terraform templates to automatically deploy in Azure with VMs
* Terraform templates write Ansible Playbook configuration, which can be customized
* Post-deploy Powershell script that adds registry entries on each Windows 10 Pro endpoint to automatically log in each username into the Domain
* Automatically uploads Badblood (does not install) https://github.com/davidprowe/BadBlood
* Post-deployment Powershell script provisions three domain users 
* Domain Users:  olivia (Domain Admin); lars (Domain User); liem (Domain User)
* All Domain User passwords:  Password123
* Domain:  RTC.LOCAL
* Domain Administrator Creds:  RTCAdmin:Password123

# JuliaRT Deployment Instructions
**Note:**  Tested on Ubuntu Linux 20.04 

Requirements:
* Azure subscription
* Terraform:  Tested on v0.12.26
* Ansible:  Tested on 2.9.6

## Installation Steps

**Note:**  Tested on Ubuntu Linux 18.04 built on Digital Ocean.

**Step 1:** Install MySQL. These steps were verified on Ubuntu Linux 18.04.

```
$sudo apt update

$sudo apt install mysql-server mysql-client libmysqlclient-dev -y

Run the mysql_secure_installation script.

$sudo mysql_secure_installation
```
