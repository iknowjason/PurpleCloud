# Installation
**Note:**  Tested on Ubuntu Linux 20.04 

## Pre-Requisites
 
* **Python:** Tested version:  3.8.10
* **Terraform:**  Tested version:  1.2.8 
* **Azure tenant with subscription**
* **Global Administrator role**

## Important Security Information:  Security Groups
Some people might be concerned about publicly exposing these cloud resources.  The ```ad.py``` script will auto-detect your source IP address and white list only that IP address.  The ```managed_identity.py``` script has a variable called src_ip which you can manually edit for your source IP address.  

### Step 1: Clone
Clone this repository

### Step 2: Install python faker 

Install the python faker using pip.  This is a dependency of some python scripts to generate users.  Faker is required for the following three scripts:  azure_ad.py, ad.py, managed_identity.py.

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

