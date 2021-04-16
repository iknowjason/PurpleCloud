
# Provider info
variable subscription_id {}
variable tenant_id {}
variable arm_client_id {}
variable arm_client_secret {}
variable aad_client_id {}
variable aad_client_secret {}

# Generic info
variable location {}

variable resource_group_name {}
variable environment_name {}

# Network
variable address_space {}
variable dns_servers {}

variable wafsubnet_name {}
variable wafsubnet_prefix {}
variable rpsubnet_name {}
variable rpsubnet_prefix {}
variable user1_subnet_name {}
variable user2_subnet_name {}
variable user1_subnet_prefix {}
variable user2_subnet_prefix {}
variable dbsubnet_name {}
variable dbsubnet_prefix {}
variable dcsubnet_name {}
variable dcsubnet_prefix {}

variable vmcount {}

variable "src_ip" {
  type = string
  default = "*"
}
