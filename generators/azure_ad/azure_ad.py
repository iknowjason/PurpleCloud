from faker import Faker
import random
import argparse
import linecache
### Install Faker:  pip3 install faker

# argparser stuff
parser = argparse.ArgumentParser(description='A script to create users in terraform format for Azure Active Directory')

# Add argument for number of users 
parser.add_argument('-c', '--count', dest='user_count')

# Add argument for upn_suffix 
parser.add_argument('-u', '--upn', dest='upn_suffix')

# Add argument for azure applications enabled 
parser.add_argument('-a', '--apps', dest='app_count')

# Add argument for azure groups enabled 
parser.add_argument('-g', '--groups', dest='group_count')

# Add argument for enabling application administrator assignment 
parser.add_argument('-aa', '--app_admin', dest='aa_enable', action='store_true')

# Add argument for enabling privileged role administrator assignment
parser.add_argument('-pra', '--pra_admin', dest='pra_enable', action='store_true')

# Add argument for enabling global administrator assignment
parser.add_argument('-ga', '--global_admin', dest='ga_enable', action='store_true')

# parse arguments
args = parser.parse_args()

# groups enabled setting
groups_enabled = False
if args.group_count:
    groups_enabled = True

# Azure AD users terraform file that is created from this script
# This creates the terraform file that is used by terraform containing users
tu_file = "users.tf"

# Azure AD applications file
ta_file = "apps.tf"

# Azure AD Groups terraform file
tg_file = "groups.tf"

# Azure AD Applications
azure_ad_applications = [
    { "HR_Application":"${var.upn_suffix} HR-App" },
    { "Finance_Application":"${var.upn_suffix} Fin-App" },
    { "ITOps_Application":"${var.upn_suffix} ITOps-App" },
    { "MailReader_Application":"${var.upn_suffix} MailReader-App" },
    { "HelpDesk_Application":"${var.upn_suffix} HelpDesk-App" }, 
    { "Marketing_Application":"${var.upn_suffix} Marketing-App" },
    { "ExecutiveReports_Application":"${var.upn_suffix} ExecutiveReports-App" }
]

# Azure AD Groups
azure_ad_groups = [
    { "Users":"${var.upn_suffix} - Users" },
    { "Sales_Team":"${var.upn_suffix} - Sales" },
    { "Executive_Team":"${var.upn_suffix} - Executive" },
    { "Marketing_Team":"${var.upn_suffix} - Marketing" },
    { "Finance_Team":"${var.upn_suffix} - Finance" },
    { "HR_Team":"${var.upn_suffix} - HR" },
    { "IT_Ops":"${var.upn_suffix} - IT Ops" },
    { "IT_Admins":"${var.upn_suffix} - IT Admins" },
    { "Helpdesk":"${var.upn_suffix} - Helpdesk" },
    { "Development":"${var.upn_suffix} - Development" },
    { "Engineering":"${var.upn_suffix} - Engineering" }
]

# Create an associated Service Principal for each Application above
create_sp = True 

# Number of applications by counting number of keys in dict
app_count = len(azure_ad_applications)

# Number of groups by counting number of keys in dict
group_count = len(azure_ad_groups)

# Check if either pra_admin or global_admin are enabled
# if they are, load a new app_list with discrete apps
app_list = []
if args.pra_enable or args.ga_enable:
    count = int(args.app_count)
    if count > app_count:
        count = app_count
    for x in range(count):
        for key in azure_ad_applications[x]:
            app_list.append(key)

# If both pra and ga are enabled, make sure unique apps assigned
pra_app = ""
ga_app = ""
if args.pra_enable and args.ga_enable:
    if int(args.app_count) < 2:
    # Make sure enough apps enabled
        print("[-] Must enable at least two apps (--apps 2) for enabling PRA and GA apps")
        exit(1)

    # Get two random selects from app list
    selections = random.sample(app_list, 2)

    # assign the pra_app
    pra_app = selections[0]

    # assign the ga_app
    ga_app = selections[1]

else:
    # either pra or ga is enabled - not both

    if args.pra_enable:
        # assign pra_app
        tmp_pra_app = random.sample(app_list, 1)
        pra_app = tmp_pra_app[0]
    elif args.ga_enable:
        # assign ga_app
        tmp_ga_app = random.sample(app_list, 1)
        ga_app = tmp_ga_app[0] 
    else:
        pass

# A list of users 
users_list = []

# Users csv file
users_csv = "azure_users.csv"

# email addresses
emails_txt = "azure_emails.txt"

# usernames
usernames_txt = "azure_usernames.txt"
  
# counter for users added to the list
users_added = 0

# duplicate count
duplicate_count = 0

# Parsing some of the arguments
if not args.user_count:
    print("[+] No users specified ~ creating 100 users by default")
    args.user_count = 100
else:
    print("[+] Number of users desired: ", args.user_count)

if not args.upn_suffix:
    print("[-] No upn_suffix specified")
    print("    [-] A upn (User Principal Name) Suffix must be specified in order to create users")
    print("    [-] Suffix can be a custom domain name you have added to Azure")
    print("    [-] Or the default, which is your tenant username + .onmicrosoft.com")
    print("    [-] Example with custom domain:")
    print("    [-] % python3 create_azure_users.py -c 20 -u acme.io")
    print("    [-] Example with default tenant username + onmicrosoft.com:")
    print("    [-] % python3 create_azure_users.py -c 20 -u acme.onmicrosoft.com")
    exit()
else:
    print("[+] upn suffix: ", args.upn_suffix)

# parse the applications
apps = 0
if not args.app_count:
    pass 
else:
    apps = int(args.app_count) 
    print("[+] Desired applications enabled:  ",args.app_count)
    if apps > app_count:
        print("[+] User specified more applications than possible.  Current limit is ",app_count)
        print("[+] Will create %s applications" % app_count)
        apps = app_count

# parse the groups
groups = 0
if not args.group_count:
    pass
else:
    groups = int(args.group_count)
    print("[+] Desired groups enabled:  ",args.group_count)
    if groups > group_count:
        print("[+] User specified more groups than possible.  Current limit is ",group_count)
        print("[+] Will create %s groups " % group_count)
        groups = group_count

# Add the string for the group name into a list, for later user mapping
# a list of the names of each group added
groups_added = []
index = 0
while index < groups:
    element = azure_ad_groups[index]
    for key in element:
        groups_added.append(key)
    index+=1

# Convert desired user count to integer
duser_count = int(args.user_count)

### Generate a user's name using Faker 
### Insert the user into a list only if unique
### Loop until the users_added equals desired users
print("[+] Creating unique user list")
while users_added < duser_count: 
    faker = Faker()
    first = faker.unique.first_name() 
    last = faker.unique.last_name() 
    display_name = first + " " + last
    if display_name in users_list:
        print("    [-] Duplicate user %s ~ not adding to users list" % (display_name))
        duplicate_count+=1
    else:
        users_list.append(display_name)
        users_added+=1

print("[+] Number of users added into list: ",len(users_list))
print("[+] Number of duplicate users filtered out: ",duplicate_count)

#### Create users csv file and dump full name, username, and email address 
print("[+] Creating output files for Azure AD Users")
print("    [+] Users csv file: ", users_csv)
with open(users_csv, 'w') as f:
    for user in users_list:
        first = user.split()[0].lower()
        last = user.split()[1].lower()
        username = first + last
        upn = args.upn_suffix
        csv_line = user + "," + username + "," + username + "@" + upn
        f.writelines(csv_line) 
        f.writelines('\n')

#### Creating usernames txt file 
print("    [+] Username txt file: ", usernames_txt)
with open(usernames_txt, 'w') as f:
    for user in users_list:
        first = user.split()[0].lower()
        last = user.split()[1].lower()
        username = first + last
        f.writelines(username) 
        f.writelines('\n')

#### Creating email addresses txt file 
print("    [+] Email addresses txt file: ", emails_txt)
with open(emails_txt, 'w') as f:
    for user in users_list:
        first = user.split()[0].lower()
        last = user.split()[1].lower()
        username = first + last
        upn = args.upn_suffix
        f.writelines(username + "@" + upn)
        f.writelines('\n')


### Now write out proper terraform
terraform_users_template = '''
# Configure the Microsoft Azure Active Directory Provider
provider "azuread" {

}

### Note:  This upn_suffix must match the tenant username with *.onmicrosoft.com, or the custom domain that has been added
### This is the domain for all new Azure AD users
variable "upn_suffix" {
  default = "REPLACE_CUSTOM_STRING"
}

# Random Pet for Azure AD users (First part of password)
resource "random_pet" "rp_string" {
  length = 2
}

# Random String for Azure AD users (Second part of password)
resource "random_string" "my_password" {
  length  = 4
  special = false
  upper   = true
}

locals {
  creds = "${random_pet.rp_string.id}-${random_string.my_password
.id}"
}

output "azure_ad_details" {

  value = <<EOS

------------------------------------
Azure AD Security Lab Setup Complete
------------------------------------
Azure AD Password: ${local.creds}

EOS
}

# write azure ad user password to file
'''

user_template = '''
resource "azuread_user" "LINE1" {
  user_principal_name = "LINE2@${var.upn_suffix}"
  display_name        = "LINE3"
  mail_nickname       = "LINE4"
  password            = local.creds
}
'''

application_admin_template = '''
# Activate the Application administrator directory role
resource "azuread_directory_role" "application_admin" {
  display_name = "Application administrator"
}

# Assign Application administrator to a random user
resource "azuread_directory_role_assignment" "assign_application_admin" {
  role_id   = azuread_directory_role.application_admin.object_id
  principal_object_id = azuread_user.userAPP_ADMIN_USER_NUM.object_id
}
'''

if not args.upn_suffix:
    print("[+] No suffix defined ~ writing default to terraform file")
    terraform_users_template = terraform_users_template.replace("REPLACE_CUSTOM_STRING","")
else:
    terraform_users_template = terraform_users_template.replace("REPLACE_CUSTOM_STRING",args.upn_suffix)

### Write the beginning portion of terraform file
print("    [+] Terraform file: ", tu_file)
azure_ad_text_file = open(tu_file, "w")
n = azure_ad_text_file.write(terraform_users_template)

### Loop and write all users in users_list to terraform file
counter = 0
for users in users_list:
    # increment the counter
    counter+=1

    # grab the template
    user_template_new = user_template

    # replace the line1 in terraform user template
    user_string = "user" + str(counter)
    user_template_new = user_template_new.replace("LINE1",user_string)

    # replace the line2 in terraform user with username in format first initial followed by last name
    first = users.split()[0].lower()
    last = users.split()[1].lower()
    # avoid duplicates with large lists of users by doing 'first_name' + 'last_name' for upn
    username = first + last
    user_template_new = user_template_new.replace("LINE2",username)

    # replace the line3 in terraform user template with Display Name
    user_template_new = user_template_new.replace("LINE3",users)

    # replace the line4 in terraform user template
    user_template_new = user_template_new.replace("LINE4",username)

    # Write the user_template_new to file
    n = azure_ad_text_file.write(user_template_new)

# Add the Application administrator role if enabled
aa_number = ""
if args.aa_enable:
    # Get the application admin template
    new_app_admin_template = application_admin_template

    # Select random user number
    random_int = random.randint(1, len(users_list))
    user_string = str(random_int)

    # replace the user number with random
    new_app_admin_template = new_app_admin_template.replace("APP_ADMIN_USER_NUM", user_string)

    # write it to users.tf string
    n = azure_ad_text_file.write(new_app_admin_template)

    aa_number = user_string

# Close the file
azure_ad_text_file.close()


def fetch_app_template():
    buffer = '''
# Create application
resource "azuread_application" "LINE1" {
  display_name = "LINE2"
}
'''
    return buffer


def fetch_sp_template():
    buffer = '''
# Create service principal 
resource "azuread_service_principal" "LINE3" {
  client_id = azuread_application.LINE4.client_id

 depends_on = [azuread_application.LINE5]
}
'''
    return buffer

pra_template = '''
# Activate the Privileged role administrator directory role
resource "azuread_directory_role" "pra" {
  display_name = "Privileged role administrator"
}

# Assign PRA to a random SP
resource "azuread_directory_role_assignment" "assign_pra" {
  role_id   = azuread_directory_role.pra.object_id
  principal_object_id = azuread_service_principal.SP_APPLICATION_NAME.object_id
}
'''

ga_template = '''
# Activate the global administrator directory role
resource "azuread_directory_role" "ga" {
  display_name = "Global administrator"
}

# Assign GA to a random SP
resource "azuread_directory_role_assignment" "assign_ga" {
  role_id   = azuread_directory_role.ga.object_id
  principal_object_id = azuread_service_principal.SP_APPLICATION_NAME.object_id
}
'''

def fetch_group_template():
    buffer = '''
# Azure AD Group
resource "azuread_group" "LINE1" {
  display_name = "LINE2"
  security_enabled = true
  members = [
    LINE3
  ]
}
'''
    return buffer

# Create apps.tf
if apps > 0:
    # Create the file, and loop through writing
    print("[+] Creating terraform file: ", ta_file)
    azure_ad_apps_file = open(ta_file, "w")

    index = 0
    while index < apps:

        for key in azure_ad_applications[index]:
            # fetch an app template
            app_template = fetch_app_template()

            # get the app name
            app_name = key
 
            # get the display name
            display_name = azure_ad_applications[index][key] 

            # replace the first line with app_name
            new_app_str = app_template.replace("LINE1",app_name)

            # replace the second line with display_name 
            new_app_str = new_app_str.replace("LINE2",display_name)

            # write the new app str
            n = azure_ad_apps_file.write(new_app_str)

            # Check if a Service Principal is desired for each application
            if create_sp:
                # This is true, so create a sp for the associated app

                # fetch a sp template
                sp_template = fetch_sp_template()

                # replace line3 with "SP_" + app_name
                new_sp_str = sp_template.replace("LINE3","SP_" + app_name)

                # replace line4 with app_name
                new_sp_str = new_sp_str.replace("LINE4",app_name)

                # replace line5 with app_name
                new_sp_str = new_sp_str.replace("LINE5",app_name)

                # write the new sp str
                n = azure_ad_apps_file.write(new_sp_str)
        index+=1

    # Check if pra is enabled
    if args.pra_enable:
        pra_assignment_string = pra_template.replace("APPLICATION_NAME", pra_app) 
        n = azure_ad_apps_file.write(pra_assignment_string)
        print("    [+] Assigning the Privileged Role Administrator to", pra_app)

    # Check if ga is enabled
    if args.ga_enable:
        ga_assignment_string = ga_template.replace("APPLICATION_NAME", ga_app) 
        n = azure_ad_apps_file.write(ga_assignment_string)
        print("    [+] Assigning the Global Administrator role to", ga_app)


    # Close the azure ad applications terraform file
    azure_ad_apps_file.close()

else:
    # don't create the file
    pass


# Count of Azure AD users
ucount = int(args.user_count)

# The name of special Azure AD groups to insert all users into - you can customize the list
all_users_groups = [
    "Users",
]

# user to group mapping
# put one user into only one group
# ugm[] is a list with the index containing a string of the group name
ugm = []
index = 0
#check if groups_added is equal to all_users_groups
if groups > 0:
    if len(all_users_groups) == len(groups_added):
        print("[-] No extra groups to add the user into")
    else: 
        while index < ucount:
            good = False
            while good is False:
                random_entry = random.choice(groups_added)
                if random_entry in all_users_groups:
                    pass
                else:
                    good = True
                    ugm.append(random_entry) 
            index+=1

# Create groups.tf
if groups > 0:
    # Create the file, and loop through writing
    print("[+] Creating terraform file: ", tg_file)
    azure_ad_groups_file = open(tg_file, "w")

    index = 0
    while index < groups:
        for key in azure_ad_groups[index]:
            # fetch a group template
            group_template = fetch_group_template()

            # get the group name
            group_name = key

            # get the display name
            display_name = azure_ad_groups[index][key]

            # replace the first line with group_name
            new_group_str = group_template.replace("LINE1",group_name)

            # replace the second line with display_name
            new_group_str = new_group_str.replace("LINE2",display_name)

            # Insert the users on LINE3
            # Check if this group is in insert all users
            if group_name in all_users_groups:
                print("    [+] Adding all Azure users to this group: ",group_name)
                count = 1
                all_users_str = ""
                while count <= ucount:
                    if count == 1:
                        user_string = "azuread_user.userINDEX.object_id,"
                    else:
                        user_string = "    " + "azuread_user.userINDEX.object_id,"
                    user_string = user_string.replace("INDEX",str(count))
                    all_users_str += user_string
                    if count == ucount:
                        all_users_str = all_users_str[:-1]
                    else:
                        all_users_str += '\n'
                    count+=1
                new_group_str = new_group_str.replace("LINE3",all_users_str)
            else:
                ## Loop through the users ugm and add them if they were selected for this group 
                indexi = 0
                all_users_str = ""
                countb = 1
                while indexi < len(ugm):
                    if ugm[indexi] == group_name:
                        #DEBUGprint("[+] Matched user indexi %d to group %s " % (indexi, group_name))
                        user_string = ""
                        # indentation if this is the first line
                        if countb == 1:
                            user_string = "azuread_user.userINDEX.object_id,"
                        else:
                            user_string = "    " + "azuread_user.userINDEX.object_id,"
                        user_string = user_string.replace("INDEX",str(indexi+1))
                        all_users_str += user_string
                        all_users_str += '\n'
                        countb+=1
                    indexi+=1

                # since the string is completed, remove the last , and carriage return
                all_users_str = all_users_str[:-2]

                # replace the string with all users in this group
                new_group_str = new_group_str.replace("LINE3",all_users_str)

            # write the new group str
            n = azure_ad_groups_file.write(new_group_str)

        index+=1

    # Close the azure ad groups terraform file
    azure_ad_groups_file.close()

else:
    # don't create the file
    pass

# output the Application Administrator if it was enabled
if args.aa_enable:
    # open the users.tf
    with open(tu_file) as fp:
        line = fp.readline()
        cnt = 1

        # create a search string based on the number that was randomly assigned to AA
        search_str = 'resource "azuread_user" "user' + aa_number + '"'

        # loop through one line at a time to find the line number
        while line:
            cnt += 1
            line = fp.readline()

            # check for the search string for AA in the line
            if search_str in line:

                # Found it, so mark down the line number
                found_line = cnt

    upn_line = linecache.getline(tu_file, found_line + 1).rstrip()
    display_line = linecache.getline(tu_file, found_line + 2).rstrip()
    upn_split = upn_line.split("=")
    display_split = display_line.split("=")
    upn1 = upn_split[1].lstrip()
    upn2 = upn1.replace('"', '')
    username = upn2.split('@')[0]
    display1 = display_split[1].lstrip()
    display_name = display1.replace('"', '')
    print("[+] Azure AD User assigned into Application Administrator role")
    print("    [+] Username:",username) 
    print("    [+] Display Name:",display_name) 
