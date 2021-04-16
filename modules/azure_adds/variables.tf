variable "resource_group_name" {
  description = "The name of the Resource Group where the Client resources will be created"
}
variable "location" {}
variable "environment_name" {}
variable "address_space" {}
variable "aads_subnet_name" {}
variable "aads_subnet_prefix" {}
variable "aads_nsg_name" {}
variable "filteredsync" {}
variable "sku" {}
variable "upn_suffix_ds" {}
variable "tenant_id_ds" {}
