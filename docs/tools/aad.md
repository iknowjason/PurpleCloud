# Azure Active Directory lab

Generating an Azure AD lab using ```azure_ad.py```.

This generates terraform formatted HCL files for ```users.tf```.  If applications and groups are created, the ```apps.tf``` and ```groups.tf``` will also be created.

### Generate a basic Azure AD lab

Usage Example:  Generate a basic Azure AD lab

```$ python3 azure_ad.py --upn rtcfingroup.com```

**Description:** 
This will generate an Azure AD range with a UPN suffix of ```rtcfingroup.com``` with 100 users. It will output three files.   The Azure AD password for all users will be automatically generated and output after terraform apply.

* **azure_users.csv:** A csv including the Azure AD user's full name, username, and email address.
* **azure_usernames.txt:**  A file including just the usernames.
* **azure_emails.txt:** A file including just the email addresses.
* **users.tf:** Terraform file that will build the users.

### Generate an Azure AD lab with 1,000 users 

Usage Example:  Generate an Azure AD lab with 1,000 users 

```$ python3 azure_ad.py --upn rtcfingroup.com --count 1000```

**Description:** 
Same as above, except generate 1,000 users in Azure AD.  Running terraform apply will generate a random password shared by all users.  The password applied to all users will be displayed at the end of ```terraform apply```.  To display the passwor again, run ```terraform output```.  


### Generate a lab with Azure applications and groups

Usage Example:  Generate a lab with Azure applications and groups

```$ python3 azure_ad.py --upn rtcfingroup.com --count 500 --apps 3 --groups 5```

**Description:**
Same as above, except generate 500 users in Azure AD.  Create 3 Azure applications and 5 groups.  Automatically put the 500 users into separate groups. 

- **apps.tf:**  A terraform file with the Azure applications.
- **groups.tf:**  A terraform file with the Azure groups.

### Generate a lab for Service Principal abuse attack primitives

Usage Example:  Generate a lab for Service Principal abuse attack primitives

```$ python3 azure_ad.py -c 25 --upn rtcfingroup.com --apps 7 -aa -ga -pra```

**Description:** 
This will generate an Azure AD range with a UPN suffix of ```rtcfingroup.com``` with 25 users. It will add some service principal abuse attack primitives to some random resources.  First, the ```--apps 7``` will add 7 Azure AD applications (App Registrations) with associated Service Principals (Enterprise Applications).  The ```-aa``` flag will assign an Application Administrator role randomly to one of the 25 Azure AD users.  The ```-ga``` flag will assign the Global Administrator role randomly to one of the 7 application SPs.  Finally, the ```-pra``` flag will assign the Privileged role administrator role randomly to one of the other 7 application SPs.
