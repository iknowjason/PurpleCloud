# Documentation
For full documentation visit:  https://iknowjason.github.io/PurpleCloud/

# 7/18/22:  Added three new Terraform Generators:  Azure Sentinel, Azure Storage, Azure Managed Identity
Create three new security labs for different use cases.  You can quickly spin up an Azure Sentinel security lab, an Azure storage account with file shares, containers, blobs, and sample files.  This also includes an Azure Key Vault with resources.  Or create an Azure managed identity security lab for offensive operations and network defenders.  See the full documentation for more details.

# 5/13/22:  Added Service Principal abuse attack primitives optional support
Added support to dynamically add some Service Principal abuse attack primitives.  This includes dynamically adding an Application Administrator to a random Azure AD user (```-aa```), a Privileged role admin to a random application SP (```-pra```), as well as a Global admin role target to a random application SP (```-ga```).  See the ```azure_ad.py``` usage examples below for more information.  We also added attack scripts for the service principal abuse scenario in ```attack_scripts``` directory.

# 2/14/22:  Valentine's Day Updates:  Python terraform generator
PurpleCloud has changed!  Introducing a Terraform generator using python.  Instead of offering terraform templates that have to be manually edited, the starting point is a Python terraform generator.  The python scripts will create your own custom terraform files based on user input.  The terraform template files have been moved to archive.

