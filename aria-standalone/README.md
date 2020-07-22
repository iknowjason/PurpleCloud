# Overview:  Aria Cloud automated deployment into Azure using Terraform with Ansible Playbook
Aria cloud can be automatically deployed into Azure.  With this configuration, an Unbuntu 18.04 LTS Linux VM is provisioned and the Aria Cloud RDP container is pulled down and runs through the Ansible Playbook.  The Azure Network Security Groups permit SSH into the Ubuntu VM, and RDP port 3389 for the pentest container.  The container automaticaly runs and exposes port 3389 listening on the same public IP address of the Ubuntu Linux VM.  This is a sister tool to the JuliaRT Cyber Range project (github.com/iknowjason/JuliaRT).  AriaCloud will soon be included in that project and automatically run as an adversary within an Active Directory domain in Azure.

# Deployment Instructions
**Note:**  Tested on Ubuntu Linux 20.04 

Requirements:
* Azure subscription
* Terraform:  Tested on v0.12.26
* Ansible:  Tested on 2.9.6

## Installation Steps

**Note:**  Tested on Ubuntu 20.04

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
and this command below.  From my testing I needed to use a role of "Owner" instead of "Contributor".  Default Microsoft documentation shows role of "Contributor" which resulted in errors.  
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

**Step 3:** Clone this repo (In case you haven't already done so)
```
$ git clone https://github.com/iknowjason/AriaCloud.git
```

**Step 4:** Using your favorite text editor, edit the **1-terraform_azure.tf** file for the Azure resource provider matching your Azure Service Principal credentials

Change into the **terraform-azure** directory.

```
cd AriaCloud/terraform-azure
```

```
vi 1-terraform_azure.tf
```

Edit these parameters in the file:
```
subscription_id = ""
client_id = ""
client_secret = ""
tenant_id = ""
```

Your file should look similar to this but with your own Azure Service Principal credentials:
```
subscription_id = "aa9d8c9f-34c2-6262-89ff-3c67527c1b22"
client_id = "7e9c2cce-8bd4-887d-b2b0-90cd1e6e4781"
client_secret = ":+O$+adfafdaF-?%:.?d/EYQLK6po9`|E<["
tenant_id = "8b6817d9-f209-2071-8f4f-cc03332847cb"
```

**Step 5:** Run the commands to initialize terraform and apply the resource plan

```
$ terraform init
$ terraform apply -auto-approve
```

This should start the Terraform automated deployment plan


**Step 6:** Verify SSH and RDP protocol access

There are two important files created in the working directory after deployment:

**1.  ssh_key.pem:**  The SSH private key used for public key authentication into the Ubuntu Linux VM.

**2.  hosts.cfg:**  This file is used by Ansible and the second line is the public IP address of the Linux VM.

Additionally, the README.ANSIBLE.txt file includes some Ansible test commands that you can run if you are having trouble.

First, take note of the public IP address of the VM.

```cat hosts.cfg```

Second, test SSH access into the VM.

```ssh -i ssh_key.pem aria@<PUBLIC IP>```

Third, test RDP access into the Aria Cloud container.  Use your preferred RDP client.

1. Verify that it works with Windows mstsc client.
2. Verify that it works with Linux **rdesktop** client
3. With the MacOS **Microsoft Remote Desktop** tool, there seems to be a small issue resulting in a black screen.

