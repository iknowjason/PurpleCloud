variable "upn_suffix" {
  description = "The User Principal Name (UPN) suffix for the AD user.  Normally this will be tenant ID of something like 'acme' followed by 'onmicrosoft.com'.  So this would look like 'acme.onmicrosoft.com' for the UPN suffix"
}

variable "tenant_id" {}
