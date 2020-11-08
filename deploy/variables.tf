#################################################################
#   Variables
#################################################################

# Provider info
variable subscription_id {}

variable client_id {}
variable client_secret {}
variable tenant_id {}

# Generic info
variable location {}

variable resource_group_name {}
variable environment_name {}

# Network
variable address_space {}

/*variable dns_servers {
  #type = "list"
  type = list(string)
}*/

variable dns_servers {}

variable wafsubnet_name {}
variable wafsubnet_prefix {}
variable rpsubnet_name {}
variable rpsubnet_prefix {}
#variable issubnet_name {}
variable user1_subnet_name {}
variable user2_subnet_name {}
#variable issubnet_prefix {}
variable user1_subnet_prefix {}
variable user2_subnet_prefix {}
variable dbsubnet_name {}
variable dbsubnet_prefix {}
variable dcsubnet_name {}
variable dcsubnet_prefix {}

# Active Directory & Domain Controller
variable prefix {}
variable dc1private_ip_address {}
variable admin_username {}
variable admin_password {}

# IIS Servers
variable vmcount {}

# Domain Controller 2
variable "dc2private_ip_address" {}
variable "domainadmin_username" {}

# SQL LB
variable "lbprivate_ip_address" {}

# SQL DB Servers
variable sqlvmcount {}

# Endpoints
variable "endpoint1_machine_name" {}
variable "endpoint1_username" {}

variable "endpoint2_machine_name" {}
variable "endpoint2_username" {}

variable "endpoint3_machine_name" {}
variable "endpoint3_username" {}

variable "src_ip" {
  type = string
  default = "*"
}

