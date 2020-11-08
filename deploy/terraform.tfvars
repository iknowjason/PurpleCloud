#################################################################
#   Variables
#################################################################

# Provider info

subscription_id = ""
client_id = ""
client_secret = ""
tenant_id = ""

# Generic info
location = "West US"

resource_group_name = "JuliaRT"

environment_name = "devops1"

# Network
address_space = "10.100.0.0/16"

#dns_servers = ["10.100.1.4", "10.100.1.5"]
dns_servers = ["10.100.1.4"]

dcsubnet_name = "sndc"

dcsubnet_prefix = "10.100.1.0/24"

wafsubnet_name = "snwf"

wafsubnet_prefix = "10.100.10.0/24"

rpsubnet_name = "snrp"

rpsubnet_prefix = "10.100.20.0/24"

user1_subnet_name = "user_finance_subnet"

user1_subnet_prefix = "10.100.30.0/24"

user2_subnet_name = "adversary_subnet"

user2_subnet_prefix = "10.100.40.0/24"

dbsubnet_name = "sndb"

dbsubnet_prefix = "10.100.50.0/24"

# Active Directory & Domain Controller 1

prefix = "rtc"

dc1private_ip_address = "10.100.1.4"

dc2private_ip_address = "10.100.1.5"

#admin_username = "AdminTest"
admin_username = "RTCAdmin"

admin_password = "Password123"

# IIS Servers

vmcount = "1"

# endpoint1
endpoint1_machine_name = "Win10-Lars"
endpoint1_username = "lars"

# endpoint2
endpoint2_machine_name = "Win10-Liem"
endpoint2_username = "liem"

# endpoint3
endpoint3_machine_name = "Win10-Olivia"
endpoint3_username = "olivia"

# Domain Controller 2
#domainadmin_username   = "'AdminTest@rtc.local'"
domainadmin_username = "'RTCAdmin@rtc.local'"

# SQL LB
lbprivate_ip_address = "10.100.50.20"

# SQL DB Servers
sqlvmcount = "1"

###
### Set variable below for IP address prefix for white listing Azure NSG
### Uncomment; otherwise, all of the public Internet will be permitted
### https://ifconfig.me/ 
### curl https://ifconfig.me
src_ip = "99.xxx.xxx.yyy"
