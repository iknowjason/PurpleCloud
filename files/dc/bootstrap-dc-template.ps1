$Cert = New-SelfSignedCertificate -DnsName $RemoteHostName, $ComputerName `
    -CertStoreLocation "cert:\LocalMachine\My" `
    -FriendlyName "Test WinRM Cert"

$Cert | Out-String

$Thumbprint = $Cert.Thumbprint

Function lwrite {
    Param ([string]$logstring)
    Add-Content $logfile -value $logstring
}

Write-Host "Enable HTTPS in WinRM"
$WinRmHttps = "@{Hostname=`"$RemoteHostName`"; CertificateThumbprint=`"$Thumbprint`"}"
winrm create winrm/config/Listener?Address=*+Transport=HTTPS $WinRmHttps

Write-Host "Set Basic Auth in WinRM"
$WinRmBasic = "@{Basic=`"true`"}"
winrm set winrm/config/service/Auth $WinRmBasic

Write-Host "Open Firewall Ports"
netsh advfirewall firewall add rule name="Windows Remote Management (HTTP-In)" dir=in action=allow protocol=TCP localport=5985
netsh advfirewall firewall add rule name="Windows Remote Management (HTTPS-In)" dir=in action=allow protocol=TCP localport=5986

# Beginning of script contents
$script_contents = '
$logfile = "C:\Terraform\user_data.log"
Function lwrite {
    Param ([string]$logstring)
    Add-Content $logfile -value $logstring
}
$mtime = Get-Date
lwrite("$mtime Starting script")

# Here are the variables used in this script rendered from terraform template
$forest = "${ad_domain}"
$forest_elements = $forest.split(".")
$ParentOU = "DC=" + $forest_elements[0] + ",DC=" + $forest_elements[1]
$storage_acct = "${storage_acct}"
$storage_container = "${storage_container}"
$users_file = "${users_file}"

lwrite("$mtime storage account: $storage_acct")
lwrite("$mtime storage container: $storage_container")
lwrite("$mtime users file: $users_file")
$mtime = Get-Date
lwrite ("$mtime Starting to verify AD forest")
$op = Get-WMIObject Win32_NTDomain | Select -ExpandProperty DnsForestName

# Check of forest is verified
if ( $op -Contains $forest ){

  $mtime = Get-Date
  lwrite ("$mtime Verified AD forest is set to $forest")

  $mtime = Get-Date
  lwrite ("$mtime Checking to add Domain Users to $forest AD Domain")

  $dst = "C:\terraform\${users_file}"
  if ( Test-Path $dst ) {
    lwrite("$mtime File already exists: $dst")
  } else {
    lwrite ("$mtime Downloading ad users list from staging container")
    $uri = "https://${storage_acct}.blob.core.windows.net/${storage_container}/${users_file}"
    lwrite ("$mtime Uri: $uri")
    Invoke-WebRequest -Uri $uri -OutFile $dst
  } 

  # Active Directory users array/collection to be imported into AD 
  $ADUsers = @()

  # Parse the CSV
  if ( Test-Path $dst ) {
    lwrite ("$mtime Importing AD users from csv: $dst")
    $ADUsers = Import-Csv -Path $dst 
  }

  # Get the unique Active Directory Groups in the array
  $adgroups = @()
  foreach($item in $ADUsers){
    $group = $item.Groups
    $adgroups += $group
  }

  # get unique AD groups
  $sorted_groups = $adgroups | Sort-Object | Get-Unique 

  # Loop through the unique AD groups and add OUs and Groups
  foreach($group in $sorted_groups) {

    # Get unique AD Group from list
    $gr = $group

    # Checking on adding this Group and OU for name below
    lwrite("$mtime Checking to add new OU and AD Group:  $gr")

    # Create new OU string 
    $newOU = "OU=$gr,$ParentOU"
    lwrite("$mtime New OU:  $newOU")
    
    try {
      $retval = Get-ADOrganizationalUnit -Identity $newOU | Out-Null
    } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
      lwrite("$mtime Adding $newOU")
      New-ADOrganizationalUnit -Name $gr -Path $parentOU
    }
 
    # check to add the AD Group
    $exists = Get-ADGroup -Filter {SamAccountName -eq $gr}
    If ($exists) {
      lwrite("$mtime AD Group already exists: $gr")
    } else {
      lwrite("$mtime Creating AD Group: $gr")
      New-ADGroup -Name $gr -SamAccountName $gr -GroupCategory Security -GroupScope Global -DisplayName $gr -Path $newOU -Description "Members of the $gr team"
    }
    
  }

  foreach ($User in $ADUsers) {

      # Get name
      $name = $User.name
      lwrite("$mtime Adding AD User $name")

      # Split the names
      $names = $name.Split(" ")

      # First Name
      $first = $names[0]

      # Last Name
      $last = $names[1]

      # Set username
      $Username = $first.ToLower() + $last.ToLower() 

      # Set password
      $Pass = $User.password
      lwrite("$mtime With password $Pass")

      # Set ou
      $OU = $User.oupath
    
      # Get the Group
      $Group = $User.groups

      # Set the path for this AD User 
      $path = "OU=$Group,$ParentOU"

      # set sam name username
      $Sam = $Username

      # set UPN
      $UPN = $Username + "@" + "${ad_domain}"

      # Set password
      $Password = $Pass | ConvertTo-SecureString -AsPlainText -Force

      # Set domain_admin property
      $DA = $User.domain_admin 
      lwrite ("$mtime DA Setting $DA")

      #Check to see if the user already exists in AD
      if (Get-ADUser -F {SamAccountName -eq $Username}) {
        Write-Warning "A user account with username $Username already exists in AD."
      } else {
        New-AdUser -SamAccountName $Username -UserPrincipalName $UPN -Name $name -GivenName $first -Surname $last -Path $path -AccountPassword $Password -ChangePasswordAtLogon $False -Enabled $True
        $mtime = Get-Date
        lwrite ("$mtime Username added: $Username to OUPath $path")

        # Add user to their mapped AD Group
        lwrite ("$mtime Username added to AD Group: $Group")
        Add-ADGroupMember -Identity $Group -Members $Sam 

        if ($DA -eq "True") {
          lwrite ("$mtime Username added to Domain Admins Group: $Username")
          Add-ADGroupMember -Identity "Domain Admins" -Members $Sam 

        }
      }
  }

  # Remove the powershell scheduled job if these tasks are completed
  $mtime = Get-Date
  lwrite ("$mtime Removing ps scheduled job ImportUsers01")
  Remove-Job -Name ImportUsers01 -Force
  Disable-ScheduledJob -Id 1

  # Remove the powershell scripts
  $mtime = Get-Date
  lwrite ("$mtime Removing ps scripts in C:\terraform")
  Remove-Item C:\Terraform\*.ps1

} else {
    $mtime = Get-Date
    lwrite ("$mtime Could not verify AD forest is set to $forest")
}

$mtime = Get-Date
lwrite ("$mtime End of script contents")
'
# End of script contents

# Write a new script for importing Domain Users
Set-Content -Path "C:\Terraform\ImportUsers.ps1" -Value $script_contents

#
# Begin - Create a powershell scheduled task to run this script once a minute
#

$jt = New-JobTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 1) -RepetitionDuration (New-Timespan -Hours 48)
Register-ScheduledJob -Name ImportUsers01 -ScriptBlock { C:\Terraform\ImportUsers.ps1 } -Trigger $jt
#
# End - Create a powershell schedule task to run this script once a minute
#

$mtime = Get-Date
lwrite ("$mtime Download Azure AD Connect msi")
# Download the Azure AD Connect msi 
$url = "https://github.com/iknowjason/BlueTools/blob/main/AzureADConnect.msi?raw=true"
$path = "C:\Users\RTCAdmin\Desktop\AzureADConnect.msi"
$client = New-Object System.Net.WebClient
$client.DownloadFile($url, $path)

$mtime = Get-Date
lwrite ("$mtime End of bootstrap script")
