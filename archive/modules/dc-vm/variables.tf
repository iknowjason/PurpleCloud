variable "resource_group_name" {
  description = "The name of the Resource Group where the Domain Controllers resources will be created"
}

variable "location" {
  description = "The Azure Region in which the Resource Group exists"
}

variable "prefix" {
  description = "The Prefix used for the Domain Controller's resources"
}

variable "ou" {
  description = "The OU used for the Domain Controller's resources"
}

variable "subnet_id" {
  description = "The Subnet ID which the Domain Controller's NIC should be created in"
}

variable "dc1private_ip_address" {}


variable "ad_domain" {
  description = "The name of the AD Domain"
}

variable "active_directory_netbios_name" {
  description = "The netbios name of the Active Directory domain, for example `consoto`"
}

variable "admin_username" {
  description = "The username associated with the local administrator account on the virtual machine"
}

variable "admin_password" {
  description = "The password associated with the local administrator account on the virtual machine"
}

variable "winrm_username" {
  description = "The Domain Administrator account used to help bootstrap Windows 10 Pro using WinRM"
}

variable "winrm_password" {
  description = "The Domain Administrator account password used to help bootstrap Windows 10 Pro using WinRM"
}

locals {
  import_command       = "Import-Module ADDSDeployment"
  password_command     = "$password = ConvertTo-SecureString ${var.admin_password} -AsPlainText -Force"
  install_ad_command   = "Add-WindowsFeature -name ad-domain-services -IncludeManagementTools"
  configure_ad_command = "Install-ADDSForest -DomainName ${var.ad_domain} -InstallDns -SafeModeAdministratorPassword $password -Force:$true"
  shutdown_command   = "shutdown -r -t 10"
  exit_code_hack     = "exit 0"
  powershell_command = "${local.import_command}; ${local.password_command}; ${local.install_ad_command}; ${local.configure_ad_command}; ${local.shutdown_command}; ${local.exit_code_hack}"
}
