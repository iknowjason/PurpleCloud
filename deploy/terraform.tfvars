# Provider info

# Azure RM 
arm_client_id = "d568c260-6e6c-49fa-b487-ff7a6db928e4"
arm_client_secret = "745455b1-23c8-4a64-bfa9-23d3818dad5d"

# Azure AD 
aad_client_id = "d568c260-6e6c-49fa-b487-ff7a6db928e4"
aad_client_secret = "745455b1-23c8-4a64-bfa9-23d3818dad5d"

# General Subscription and Tenant ID
subscription_id = "562db19c-f304-45df-8cc6-e93f7daed8cb"
tenant_id = "1a82558d-66e0-48b0-b370-72df4caf1852"

# Location, Resource Group, and environment name
location = "East US"
resource_group_name = "purplecloud"
environment_name = "AAD_Lab_final_se"

# Network
address_space = "10.100.0.0/16"
dns_servers = ["10.100.1.4"]
dcsubnet_name = "sndc"
dcsubnet_prefix = "10.100.1.0/24"
rpsubnet_name = "snrp"
rpsubnet_prefix = "10.100.20.0/24"
wafsubnet_name = "snwf"
wafsubnet_prefix = "10.100.10.0/24"
user1_subnet_name = "user_finance_subnet"
user1_subnet_prefix = "10.100.30.0/24"
user2_subnet_name = "adversary_subnet"
user2_subnet_prefix = "10.100.40.0/24"
dbsubnet_name = "sndb"
dbsubnet_prefix = "10.100.50.0/24"

vmcount = "1"

###
### Set variable below for IP address prefix for white listing Azure NSG
### Uncomment; otherwise, all of the public Internet will be permitted
### https://ifconfig.me/ 
### curl https://ifconfig.me
src_ip = "99.182.28.252"
