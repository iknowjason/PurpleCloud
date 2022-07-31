# Azure Managed Identity lab

```$ python3 managed_identity.py -u <UPN_SUFFIX> -n <NAME> -l <LOCATION> -a <ADMIN_USERNAME> -p <PASSWORD> -sa -ua <USER_ASSGNED_IDENTITY>```

Create a security lab for practicing managed identity attack and defense.  Generates a terraform format HCL file for ```managed_identity.tf```,  ```providers.tf```, and ```mi_user.tf```.

### Resources Created
* One Azure AD User with a configurable Role Assignment (Default:  Virtual Machine Contributor)
* One Azure VM with a Managed Identity configured (Default:  User Assigned Identity with Reader on the Subscription)
* Azure Storage Account (1)
* Azure Containers (3)
The containers have three different access levels (Blob, Container, Private)
* Azure Blobs (3).  All three are uploaded to all three containers.
* Azure Shares (2)
* Two files are uploaded to the two shares
* Azure Key Vault
* Secrets (3)
* Private Keys (1)
* Certificates (1)

### Options

```-u <UPN_SUFFIX>```:  Mandatory.  Specify the correct UPN Suffix for your tenant.  Needed for creating the Azure AD user.

```-a <ADMIN_USERNAME>```:  Specify the local Administrator Username for the Windows 10 Pro Azure VM. (Default:  MIAdmin)

```-p <PASSWORD>```: Specify the password for the local Administrator account on the VM as well as the Azure AD user (Default:  Auto-generated)

```-sa```: Enables the System Assigned Identity for the Azure VM (Note:  both user assigned and system assigned can be enabled)

```-ua reader|contributor|owner```: Enables the User Assigned Identity for the Azure VM with possible values of reader, contributor, owner (Default:  reader)

```-n <NAME>```:  Specify a resource group name and name for other resources

```-l <LOCATION>```:  Specify a different location (Default: centralus)

### Other Variables in Script

```
# This is the src_ip for white listing Azure NSGs
# allow every public IP address by default
variable "src_ip" {
  default = "0.0.0.0/0"
}
```

The role of the managed identity by default is scoped to the subscription

```
# Assign the reader role on the Key vault to the Managed Identity
resource "azurerm_role_assignment" "uai" {
  #Scope to the key vault in line below
  #scope                = azurerm_key_vault.example.id
  #Scope to the subscription in line below
  scope                = data.azurerm_subscription.mi.id
  role_definition_name = "ROLE_DEFINITION_NAME"
  principal_id         = azurerm_user_assigned_identity.uai.principal_id
}
```

The role of the Azure AD user
```
# The role scoped to subscription for AAD user
# uncomment as needed
variable "user_role" {
  default = "Virtual Machine Contributor"
  #default = "Contributor"
  #default = "Reader"
  #default = "Owner"
}
```
