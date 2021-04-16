## Specify all of the different Azure providers
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  
    azuread = {
      source = "hashicorp/azuread"
      version = "=1.4.0"
    }
  }
}

# Configure the Microsoft Azure Active Directory Provider
provider "azuread" {
  
  tenant_id = var.tenant_id
  client_id = var.aad_client_id
  client_secret = var.aad_client_secret
}

# Configure the Microsoft Azure Resource Manager Provider
provider "azurerm" {
  features {}
 
  subscription_id = var.subscription_id
  tenant_id = var.tenant_id
  client_id = var.arm_client_id
  client_secret = var.arm_client_secret

}

####
# Declare some local variables
####
locals {

  # Azure AD specific
  tenant_id	   	   = "acme"
  # User principal name setting (UPN)
  # Use this suffix below if you're using the default onmicrosoft.com as your UPN (No custom domain)
  #upn_suffix		   = "${local.tenant_id}.onmicrosoft.com"
  # Use this suffix below if you've set up a custom domain in Azure AD
  upn_suffix		   = "acme.com"

  # Azure AD Domain Services
  tenant_id_ds             = "acme"
  # User principal name setting (UPN)
  # Use this suffix below if you're using the default onmicrosoft.com as your UPN (No custom domain)
  upn_suffix_ds            = "${local.tenant_id_ds}.onmicrosoft.com"
  # Use this suffix below if you've set up a custom domain in Azure AD
  #upn_suffix              = "acme.com"
  aads_subnet_name	   = "aads-subnet"
  aads_nsg_name	           = "aads-nsg"
  # The aads_subnet_prefix below must match with 'addressPrefix' in arm/template.json
  aads_subnet_prefix	   = "10.100.20.0/24"
  filteredsync		   = "Disabled"
  sku		           = "Standard"

  # relociraptor + HELK system (velocihelk)
  vhprivate_ip_address      = "10.100.1.5"

  # Active Directory Domain Controller
  ad_domain                 = "rtc.local"
  prefix                    = "rtc"
  suffix		    = "local"
  ou			    = "OU=Finance,ou=users,dc=${local.prefix},dc=${local.suffix}"
  dc1private_ip_address     = "10.100.1.4"
  admin_username            = "RTCAdmin"
  admin_password            = "Password123"
  # This winrm_username variable below is the Domain Administrator account used to help bootstrap each Windows 10 Pro system
  # Jason Lindqvist, Domain Admin
  winrm_username            = "jason"
  winrm_password            = "Password123"

  # endpoint1 - Windows 10 Pro
  endpoint1_ip	            = "10.100.30.11"
  endpoint1_hostname        = "Win10-Lars"
  endpoint1_ad_user         = "lars"
  endpoint1_ad_password     = "Password123"
  endpoint1_install_agent   = true 
  endpoint1_join_domain	    = true 

  # endpoint2 - Windows 10 Pro (Current configuration is set to Domain Administrator)
  endpoint2_ip	            = "10.100.30.12"
  endpoint2_hostname        = "Win10-Olivia"
  endpoint2_ad_user         = "olivia"
  endpoint2_ad_password     = "Password123"
  endpoint2_install_agent   = true
  endpoint2_join_domain	    = true 

  # endpoint3 - Windows 10 Pro
  endpoint3_ip	            = "10.100.30.13"
  endpoint3_hostname        = "Win10-Liem"
  endpoint3_ad_user         = "liem"
  endpoint3_ad_password     = "Password123"
  endpoint3_install_agent   = true
  endpoint3_join_domain	    = true

  # endpoint4 - Windows 10 Pro
  endpoint4_ip	            = "10.100.30.14"
  endpoint4_hostname        = "Win10-John"
  endpoint4_ad_user         = "john"
  endpoint4_ad_password     = "Password123"
  endpoint4_install_agent   = true
  endpoint4_join_domain	    = true
}

##########################################################
## Azure AD Module - Create Azure AD Users, Groups, and Application 
##########################################################
/*module "azure_ad" {
  source              = "../modules/azure_ad"
  upn_suffix	      = local.upn_suffix
  tenant_id	      = local.tenant_id
}*/

##########################################################
## Azure AD Domain Services Module - Create Managed AD in the Azure cloud 
##########################################################
/*module "azure_adds" {
  source              = "../modules/azure_adds"
  location            = var.location
  upn_suffix_ds	      = local.upn_suffix_ds
  tenant_id_ds	      = local.tenant_id_ds
  resource_group_name = module.network.out_resource_group_name
  environment_name    = var.environment_name
  address_space       = var.address_space
  aads_nsg_name       = local.aads_nsg_name
  aads_subnet_name    = local.aads_subnet_name
  aads_subnet_prefix  = local.aads_subnet_prefix
  filteredsync	      = local.filteredsync
  sku	              = local.sku
}*/

##########################################################
## Create Resource group Network & subnets
##########################################################
module "network" {
  source              = "../modules/network"
  address_space       = var.address_space
  dns_servers         = var.dns_servers
  environment_name    = var.environment_name
  resource_group_name = var.resource_group_name
  location            = var.location
  src_ip              = var.src_ip
  dcsubnet_prefix     = var.dcsubnet_prefix
  dcsubnet_name       = var.dcsubnet_name
  wafsubnet_name      = var.wafsubnet_name
  wafsubnet_prefix    = var.wafsubnet_prefix
  rpsubnet_name       = var.rpsubnet_name
  rpsubnet_prefix     = var.rpsubnet_prefix
  user1_subnet_name   = var.user1_subnet_name
  user1_subnet_prefix = var.user1_subnet_prefix
  user2_subnet_name   = var.user2_subnet_name
  user2_subnet_prefix = var.user2_subnet_prefix
  dbsubnet_name       = var.dbsubnet_name
  dbsubnet_prefix     = var.dbsubnet_prefix
}

##########################################################
## Create the Adversary Linux VM 
##########################################################
/*module "adversary-vm" {
  source              = "../modules/adversary-vm"
  resource_group_name = module.network.out_resource_group_name
  location            = var.location
  prefix              = local.prefix
  subnet_id           = module.network.user2_subnet_subnet_id
}*/

##########################################################
## Create DC VM & AD Forest
##########################################################
module "dc-vm" {
  source                        = "../modules/dc-vm"
  resource_group_name           = module.network.out_resource_group_name
  location                      = var.location
  ad_domain                     = local.ad_domain
  prefix                        = local.prefix
  ou				= local.ou
  subnet_id                     = module.network.dc_subnet_subnet_id
  active_directory_netbios_name = local.prefix
  dc1private_ip_address         = local.dc1private_ip_address
  admin_username                = local.admin_username
  admin_password                = local.admin_password
  winrm_username                = local.winrm_username
  winrm_password                = local.winrm_password
}

##########################################################
## Create HELK + Velociraptor System
##########################################################
module "velocihelk" {
  source                        = "../modules/velocihelk-vm"  # velocihelk = Velociraptor and HELK
  resource_group_name           = module.network.out_resource_group_name
  location                      = var.location
  prefix                        = local.prefix
  subnet_id                     = module.network.dc_subnet_subnet_id
  vhprivate_ip_address          = local.vhprivate_ip_address
}

### Create Windows 10 Pro VM #1
module "win10-vm1" {
  source                    = "../modules/win10-vm"
  resource_group_name       = module.network.out_resource_group_name
  location                  = var.location
  prefix                    = local.prefix
  ad_domain                 = local.ad_domain
  dc_ip                     = local.dc1private_ip_address
  endpoint_hostname         = local.endpoint1_hostname
  endpoint_ip               = local.endpoint1_ip
  endpoint_ad_user          = local.endpoint1_ad_user
  endpoint_ad_password      = local.endpoint1_ad_password
  subnet_id                 = module.network.user1_subnet_subnet_id
  admin_username            = local.admin_username
  admin_password            = local.admin_password
  winrm_username            = local.winrm_username
  winrm_password            = local.winrm_password
  install_agent		    = local.endpoint1_install_agent
  join_domain		    = local.endpoint1_join_domain
  vmcount                   = var.vmcount
}

### Create Windows 10 Pro VM #2
/*module "win10-vm2" {
  source                    = "../modules/win10-vm"
  resource_group_name       = module.network.out_resource_group_name
  location                  = var.location
  prefix                    = local.prefix
  ad_domain                 = local.ad_domain
  dc_ip                     = local.dc1private_ip_address
  endpoint_hostname         = local.endpoint2_hostname
  endpoint_ip               = local.endpoint2_ip
  endpoint_ad_user          = local.endpoint2_ad_user
  endpoint_ad_password      = local.endpoint2_ad_password
  subnet_id                 = module.network.user1_subnet_subnet_id
  admin_username            = local.admin_username
  admin_password            = local.admin_password
  winrm_username            = local.winrm_username
  winrm_password            = local.winrm_password
  install_agent		    = local.endpoint2_install_agent
  join_domain		    = local.endpoint2_join_domain
  vmcount                   = var.vmcount
}*/

### Create Windows 10 Pro VM #3
/*module "win10-vm3" {
  source                    = "../modules/win10-vm"
  resource_group_name       = module.network.out_resource_group_name
  location                  = var.location
  prefix                    = local.prefix
  ad_domain                 = local.ad_domain
  dc_ip                     = local.dc1private_ip_address
  endpoint_hostname         = local.endpoint3_hostname
  endpoint_ip               = local.endpoint3_ip
  endpoint_ad_user          = local.endpoint3_ad_user
  endpoint_ad_password      = local.endpoint3_ad_password
  subnet_id                 = module.network.user1_subnet_subnet_id
  admin_username            = local.admin_username
  admin_password            = local.admin_password
  winrm_username            = local.winrm_username
  winrm_password            = local.winrm_password
  install_agent		    = local.endpoint3_install_agent
  join_domain		    = local.endpoint3_join_domain
  vmcount                   = var.vmcount
}*/

### Create Windows 10 Pro VM #4
/*module "win10-vm4" {
  source                    = "../modules/win10-vm"
  resource_group_name       = module.network.out_resource_group_name
  location                  = var.location
  prefix                    = local.prefix
  ad_domain                 = local.ad_domain
  dc_ip                     = local.dc1private_ip_address
  endpoint_hostname         = local.endpoint4_hostname
  endpoint_ip               = local.endpoint4_ip
  endpoint_ad_user          = local.endpoint4_ad_user
  endpoint_ad_password      = local.endpoint4_ad_password
  subnet_id                 = module.network.user1_subnet_subnet_id
  admin_username            = local.admin_username
  admin_password            = local.admin_password
  winrm_username            = local.winrm_username
  winrm_password            = local.winrm_password
  install_agent		    = local.endpoint4_install_agent
  join_domain		    = local.endpoint4_join_domain
  vmcount                   = var.vmcount
}*/
