variable "prefix" {
  description = "The Prefix used for the Linux Client resources"
}

variable "subnet_id" {
  description = "The Subnet ID which the Linux Client's NIC should be created in"
}

variable "resource_group_name" {
  description = "The name of the Resource Group where the Client resources will be created"
}

variable "location" {
  description = "The Azure Region in which the Resource Group exists"
}

