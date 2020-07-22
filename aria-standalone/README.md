# Overview:  Aria Cloud Terraform + Ansible Deployment
Pentest Cyber Range for a small Active Directory Domain.  Automated templates for building your own Pentest/Red Team/Cyber Range in the Azure cloud!  JuliaRT is a small Active Directory enterprise deployment automated with Terraform / Ansible Playbook templates to be deployed in Azure.
# Quick Fun Facts:
* Deploys one (1) Windows 2019 Domain Controller and three (3) Windows 10 Pro Endpoints
* Automatically joins the three Windows 10 computers to the AD Domain
* Uses Terraform templates to automatically deploy in Azure with VMs
* Terraform templates write Ansible Playbook configuration, which can be customized
* Post-deploy Powershell script that adds registry entries on each Windows 10 Pro endpoint to automatically log in each username into the Domain as respective user
* Automatically uploads Badblood (but does not install) if you prefer to generate thousands of simulated users https://github.com/davidprowe/BadBlood
* Post-deployment Powershell script provisions three domain users on the 2019 Domain Controller and can be customized for many more
* Domain Users:  olivia (Domain Admin); lars (Domain User); liem (Domain User)
* All Domain User passwords:  Password123
* Domain:  RTC.LOCAL
* Domain Administrator Creds:  RTCAdmin:Password123
* Deploys four IP subnets
* Deploys intentionally insecure Azure Network Security Groups (NSGs) that allow RDP, WinRM (5985, 5986) from the Public Internet.  Secure this as per your requirements.  WinRM is used to automatically provision the hosts.

# JuliaRT Deployment Instructions
**Note:**  Tested on Ubuntu Linux 20.04 

Requirements:
* Azure subscription
* Terraform:  Tested on v0.12.26
* Ansible:  Tested on 2.9.6

## Installation Steps

**Note:**  Tested on Ubuntu 20.04

**Step 1:** Install Terraform and Ansible on your Linux system
