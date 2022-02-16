# Disable loading of default AD drive
#$Env:ADPS_LoadDefaultDrive = 0

# Import active directory module for running AD cmdlets
Import-Module activedirectory

#Store the data from ADUsers.csv in the $ADUsers variable
$ADUsers = Import-csv C:\terraform\users.csv

#Loop through each row containing user details in the CSV file
foreach ($User in $ADUsers)
{
	$Username    = $User.username
	$Password    = $User.password
	$Firstname   = $User.firstname
	$Lastname    = $User.lastname
	$DisplayName = $Firstname + " " + $Lastname
	$OU          = $User.ou
	$Sam         = $User.username
	#$UPN          = $User.username + "ad.rtc.local"
	$UPN          = $User.username + "@rtc.local"
	$Password    = $User.Password | ConvertTo-SecureString -AsPlainText -Force

	#Check to see if the user already exists in AD
	if (Get-ADUser -F {SamAccountName -eq $Username})
	{
		#If user does exist, give a warning
		Write-Warning "A user account with username $Username already exist in Active Directory."
	}
	else
	{
		#Account will be created in the OU provided by the $OU variable read from the CSV file
		New-AdUser -SamAccountName $Username -UserPrincipalName $UPN -Name $DisplayName -GivenName $Firstname -Surname $Lastname -AccountPassword $Password -ChangePasswordAtLogon $False -Enabled $True
		Write-Output "Username added: $Username" 
	}
}

# Add username 'olivia' into 'Domain Admins'
Add-ADGroupMember -Identity "Domain Admins" -Members "olivia"
