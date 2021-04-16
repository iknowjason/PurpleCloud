locals {
  location = var.location 
  apiVersion  = "2017-06-01"
  domainConfigurationType = "FullySynced"
  domainName              = var.upn_suffix_ds
  filteredSync            = var.filteredsync 
  subnetName              = var.aads_subnet_name 
  nsgName                 = var.aads_nsg_name 
  sku                     = var.sku 
  subnetAddressPrefix     = var.aads_subnet_prefix
  vnetName		  = "${var.resource_group_name}-net"
  vnetLocation		  = var.location 
  vnetResourceGroup       = var.resource_group_name 
  notificationSettings    = {
    "notifyGlobalAdmins" = "Enabled",
    "notifyDcAdmins" = "Enabled",
    "additionalRecipients" = [] 
  }
  members = [
    "array",
    "of",
    "members"
  ]
  enabled = true
  tags = {
    "key" = "value",
    "simple" = "store"
  }

  # this is the format required by ARM templates
  parameters_body = {
    location = {
      value = local.location
    },
    apiVersion = {
      value = local.apiVersion
    },
    domainConfigurationType = {
      value = local.domainConfigurationType
    },
    domainName = {
      value = local.domainName
    },
    filteredSync = {
      value = local.filteredSync
    },
    subnetName = {
      value = local.subnetName
    },
    vnetName = {
      value = local.vnetName
    },
    vnetResourceGroup = {
      value = local.vnetResourceGroup
    },
    vnetLocation = {
      value = local.vnetLocation
    },
    notificationSettings = {
      value = local.notificationSettings
    },
    nsgName = {
      value = local.nsgName
    },
    sku = {
      value = local.sku
    },
    subnetAddressPrefix = {
      value = local.subnetAddressPrefix
    },
    tags = {
      value = local.tags 
    }
  }
}

resource "azurerm_template_deployment" "aadds" {

  name                = "aads_template-01"
  resource_group_name = var.resource_group_name
  template_body       = file("${path.module}/arm/template.json")
  parameters_body = jsonencode(local.parameters_body)
  deployment_mode = "Incremental"
  #depends_on      = [module.network.azurerm_virtual_network]
}
