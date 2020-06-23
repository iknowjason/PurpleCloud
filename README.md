# About JuliaRT
Pentest Cyber Range for a small Active Directory Domain.  Automated templates for building your own Pentest/Red Team/Cyber Range in the Azure cloud!  JuliaRT is a small Active Directory enteprise deployment automated with Terraform / Ansible Playbook templates to be deployed in Azure.
# Quick Fun Facts:
* Deploys one (1) Windows 2019 Domain Controller and three (3) Windows 10 Pro Endpoints
* Automatically joins the three Windows 10 computers to the AD Domain
* Uses Terraform templates to automatically deploy in Azure with VMs
* Terraform templates write Ansible Playbook configuration, which can be customized
* Post-deploy Powershell script that adds registry entries on each Windows 10 Pro endpoint to automatically log in each username into the Domain as respective user
* Automatically uploads Badblood (but does not install) if you prefer to generate thousands of simulated users https://github.com/davidprowe/BadBlood
* Post-deployment Powershell script provisions three domain users on the 2019 Domain Controller 
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

**Step 1:** Install Terraform and Ansible on your Linux system

Download and install Terraform for your platform --> https://www.terraform.io/downloads.html

Install Ansible
```
$ sudo apt-get install ansible
```

**Step 2:** Set up an Azure Service Principal on your Azure subscription that allows Terraform to automate tasks under your Azure subscription

Follow the exact instructions in this Microsoft link:
https://docs.microsoft.com/en-us/azure/developer/terraform/getting-started-cloud-shell

These were the two basic commands that were run based on this link above:
```
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<subscription_id>
```
and
```
az login --service-principal -u <service_principal_name> -p "<service_principal_password>" --tenant "<service_principal_tenant>"
```
Take note of the following which we will use next to configure our Terraform Azure provider:
```
subscription_id = ""
client_id = ""
client_secret = ""
tenant_id = ""
```

**Step 3:** Clone this repo
```
$ git clone https://github.com/iknowjason/juliart.git
```

**Step 4:** Using your favorite text editor, edit the terraform.tfvars file for the Azure resource provider matching your Azure Service Principal credentials

```
cd juliart/deploy
vi terraform.tfvars
```

Edit these parameters in the terraform.tfvars file:
```
subscription_id = ""
client_id = ""
client_secret = ""
tenant_id = ""
```

Should look something like this:
```
subscription_id = "aa9d8c9f-34c2-6262-89ff-3c67527c1b22"
client_id = "7e9c2cce-8bd4-887d-b2b0-90cd1e6e4781"
client_secret = ":+O$+adfafdaF-?%:.?d/EYQLK6po9`|E<["
tenant_id = "8b6817d9-f209-2071-8f4f-cc03332847cb"
```
