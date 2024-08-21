# Installation
**Note:**  Tested on Ubuntu Linux 20.04 

## Pre-Requisites
 
* **Python:** Tested version:  3.8.10
* **Terraform:**  Tested version:  1.2.8 
* **Azure tenant with subscription**
* **Global Administrator role**

## Important Security Information:  Security Groups
Some people might be concerned about publicly exposing these cloud resources.  The following scripts are built to use terraform that will auto-detect your source IP address and white list only that IP address.  If you change locations, you can simply run ```terraform apply``` and the Azure NSG firewall rules will change your allowed IP address using terraform.  Here are the scripts supporting this and these are all of the scripts that create Azure VMs and expose RDP (only from the white listed IP):  aadjoin.py, ad.py, adfs.py, managed_identity.py, sentinel.py. 

### Step 1: Clone
Clone this repository

```
git clone https://github.com/iknowjason/PurpleCloud.git 
```

**Important Note on Large File Support:** This repository has a ```shared``` directory that uses some larger files (i.e., Sysmon, Azure AD Connect, Velociraptor, Winlogbeat).  If you wish to use the large files in this repository and download them with the git client, please make sure your git client supports **git-lfs** (large file support).  If you don't want to install the git-lfs extension but you still want to download the large files, you can simply download the zip file with your browser.  It will include the large files.   

On Ubuntu linux, just run this to install git-lfs extension:
```
apt-get install git-lfs
```

### Step 2: Install python faker 

Install the python faker using pip.  This is a dependency of some python scripts to generate users.  Faker is required for the following scripts:  azure_ad.py, ad.py, managed_identity.py, sentinel.py, adfs.py, and aadjoin.py.

```
pip3 install faker
```

### Step 3: Environment Setup

Set up your environment to use Terraform

There are two ways to set up your environment in order to run terraform.

#### Option 1:  az login as Global Administrator
Install the az cli tool.  Type ```az login``` and follow the prompts to authenticate as a Global Administrator.

This is the fastest way.

#### Option 2:  Create an Azure Service Principal

Creating an Azure Service Principal and assigning it permissions is educational, but slower.

After you have a valid Azure subscription, create an Azure Service Principal with the correct permissions and add the four environment variables to your local shell using .env or .envrc:

```
export ARM_SUBSCRIPTION_ID="YOUR_SERVICE_PRINCIPAL_VALUES"
export ARM_TENANT_ID="YOUR_SERVICE_PRINCIPAL_VALUES"
export ARM_CLIENT_ID="YOUR_SERVICE_PRINCIPAL_VALUES"
export ARM_CLIENT_SECRET="YOUR_SERVICE_PRINCIPAL_VALUES"
```

Here are some references for creating a Service Principal to use with Azure.

* Microsoft Reference Docs:  Creating a Service Principal

```
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret
```

* Microsoft Reference Docs:  Configuring a Service Principal to manage Azure Active Directory

```
https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/guides/service_principal_configuration
```

* Microsoft Reference Docs:  Creating a Service Principal in Cloud Shell with Bash

```
https://docs.microsoft.com/en-us/azure/developer/terraform/get-started-cloud-shell-bash?tabs=bash
```

These are the settings that have worked best.  For Azure AD, set up the Service Principal as Global Administrator and assign the following Graph API permissions:

- Application.ReadWrite.All
- User.ReadWrite.All
- Group.ReadWrite.All

For building the Azure infrastructure resources, assigning the Service Principal a role of ```Owner``` can help as well.

**Important Note:**  The Sentinel generator requires a special permission that adds an Entra ID diagnostic setting.  If you want to use the ```sentinel.py``` generator and you are using a Service Principal, you need to add a special permission to the Service Principal you are using with terraform:

Adding this diagnostic setting (for Entra ID logging to Log Analytics Workspace) requires special privileges for your terraform Service Principal to have authorized to read and write changes to aadiam resources (Azure Diagnostic Settings).  You must add a special role to your SP.  You can let terraform run and it will show an error.  You can simply comment out this resource temporarily.

1. Ensure that owner permissions are added for the SP

2. Ensure that SP has Global Administrator permissions

3. Get the ```object_id``` of your terraform service principal.  You can get this from the Azure portal or by looking at the error returned by terraform.

4. Run this command (below) while logged in as global admin with **az login**, changing the ```SP_OBJECT_ID``` to be your terraform Service Principal's ```object_id```.  The ```--role ID``` is for owner role which you should have added for your SP in step 1.

```commandline
az role assignment create --assignee-principal-type  ServicePrincipal --assignee-object-id <SP_OBJECT_ID> --scope "/providers/Microsoft.aadiam" --role b24988ac-6180-42a0-ab88-20f7382dd24c
```

### Step 4: Generate Terraform  

Run one of the PurpleCloud scripts to generate terraform.  Each generator lives in a separate directory.  See the usage section for examples.
 
### Step 5: Run Terraform
  
Run terraform 
```
terraform init
terraform plan -out=run.plan
terraform apply run.plan
```

## Destroying the Range

Destroy the range resources when you are finished:

```
terraform destroy
```

