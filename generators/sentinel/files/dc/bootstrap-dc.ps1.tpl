$Cert = New-SelfSignedCertificate -DnsName $RemoteHostName, $ComputerName `
    -CertStoreLocation "cert:\LocalMachine\My" `
    -FriendlyName "Test WinRM Cert"

$Cert | Out-String
$Thumbprint = $Cert.Thumbprint

$logfile = "C:\Terraform\bootstrap_log.log"
Function lwrite {
    Param ([string]$logstring)
    Add-Content $logfile -value $logstring
}

$mtime = Get-Date
lwrite("$mtime Starting bootstrap")
lwrite("$mtime Enable HTTPS in WinRM")
$WinRmHttps = "@{Hostname=`"$RemoteHostName`"; CertificateThumbprint=`"$Thumbprint`"}"
winrm create winrm/config/Listener?Address=*+Transport=HTTPS $WinRmHttps

lwrite("$mtime Set Basic Auth in WinRM")
$WinRmBasic = "@{Basic=`"true`"}"
winrm set winrm/config/service/Auth $WinRmBasic

lwrite("$mtime Open Firewall Ports")
netsh advfirewall firewall add rule name="Windows Remote Management (HTTP-In)" dir=in action=allow protocol=TCP localport=5985
netsh advfirewall firewall add rule name="Windows Remote Management (HTTPS-In)" dir=in action=allow protocol=TCP localport=5986

# Beginning of script contents
$script_contents = '
$logfile = "C:\Terraform\bootstrap_log.log"
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

if (Get-Module -ListAvailable -Name ADDSDeployment) {
    Write-Host "ADDSDeployment module is already installed. Skipping installation"
    lwrite("$mtime ADDSDeployment module is already installed. Skipping installation")
} else {
    Write-Host "Going to install ADDSForest"
    lwrite("$mtime Going to install ADDS Services and Forest")

    $mtime = Get-Date
    lwrite("$mtime Add Windows Feature ad-domain-services")
    Add-WindowsFeature -Name ad-domain-services -IncludeManagementTools

    $mtime = Get-Date
    lwrite("$mtime Import Module ADDSDeployment")
    Import-Module ADDSDeployment

    $mtime = Get-Date
    lwrite("$mtime Running Install-ADDSForest cmdlet")
    $password = ConvertTo-SecureString ${admin_password} -AsPlainText -Force
    Install-ADDSForest -DomainName $forest -InstallDns -SafeModeAdministratorPassword $password -Force:$true
    shutdown -r -t 10 
}

lwrite ("$mtime Starting to verify AD forest")
# Check of forest is verified
$op = Get-WMIObject Win32_NTDomain | Select -ExpandProperty DnsForestName
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
# Begin - Create a powershell scheduled job to run this script once a minute
#

$jt = New-JobTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 1) -RepetitionDuration (New-Timespan -Hours 48)
Register-ScheduledJob -Name ImportUsers01 -ScriptBlock { C:\Terraform\ImportUsers.ps1 } -Trigger $jt
#
# End - Create a powershell schedule job to run this script once a minute
#

$mtime = Get-Date
lwrite ("$mtime Download Azure AD Connect msi")
# Download the Azure AD Connect msi 
$path = "C:\Users\${admin_username}\Desktop\AzureADConnect.msi"
if ( Test-Path $path ) {
  lwrite("$mtime File already exists: $path")
} else {
  lwrite ("$mtime Downloading Azure AD Connect msi from staging container")
  $uri = "https://${storage_acct}.blob.core.windows.net/${storage_container}/${aadconnect_file}"
  lwrite ("$mtime Uri: $uri")
  Invoke-WebRequest -Uri $uri -OutFile $path
}

# Download Sysmon
$mtime = Get-Date
lwrite("$mtime Download Sysmon")
(New-Object System.Net.WebClient).DownloadFile('https://${storage_acct_s}.blob.core.windows.net/${storage_container_s}/${sysmon_zip_s}', 'C:\terraform\Sysmon.zip')

# Download Sysmon config xml
$mtime = Get-Date
if (-not(Test-Path -Path "C:\terraform\sysmonconfig-export.xml" -PathType Leaf)) {
  try {
    lwrite("$mtime Download Sysmon config")
    (New-Object System.Net.WebClient).DownloadFile('https://${storage_acct_s}.blob.core.windows.net/${storage_container_s}/${sysmon_config_s}', 'C:\terraform\sysmonconfig-export.xml')
  } catch {
    lwrite("$mtime Error downloading Sysmon config")
  }
}

# Expand the Sysmon zip archive
$mtime = Get-Date
lwrite("$mtime Expand the sysmon zip file")
Expand-Archive -Force -LiteralPath 'C:\terraform\Sysmon.zip' -DestinationPath 'C:\terraform\Sysmon'

# Copy the Sysmon configuration for SwiftOnSecurity to destination Sysmon folder
$mtime = Get-Date
lwrite("$mtime Copy the Sysmon configuration for SwiftOnSecurity to destination Sysmon folder")
Copy-Item "C:\terraform\sysmonconfig-export.xml" -Destination "C:\terraform\Sysmon"

# Install Sysmon
$mtime = Get-Date
lwrite("$mtime Install Sysmon for Sentinel")
C:\terraform\Sysmon\sysmon.exe -accepteula -i C:\terraform\Sysmon\sysmonconfig-export.xml

lwrite("$mtime Install Powershell Core")
iwr -Uri "https://github.com/PowerShell/PowerShell/releases/download/v7.4.1/PowerShell-7.4.1-win-x64.msi" -Outfile "C:\terraform\Powershell-7.4.1-win-x64.msi"
msiexec.exe /package "C:\terraform\PowerShell-7.4.1-win-x64.msi" /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1 USE_MU=1 ENABLE_MU=1 ADD_PATH=1

# OpenSSH Server
lwrite("$mtime Install of OpenSSH Server")
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH*'
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Start OpenSSH service
lwrite("$mtime Start SSH Server service")
Start-Service sshd

# Set startup automatic
Set-Service -Name sshd -StartupType 'Automatic'

# Firewall rules confirmed
if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
    lwrite("$mtime Firewall Rule 'OpenSSH-Server-In-TCP' does not exist")
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
} else {
    lwrite("$mtime Firewall rule 'OpenSSH-Server-In-TCP' created")
}

# Change sshd_config file
$sshd_config_file = "C:\ProgramData\ssh\sshd_config"

# Allow PasswordAuthentication to yes
((Get-Content -path $sshd_config_file -raw) -replace '#PasswordAuthentication yes', 'PasswordAuthentication yes') | Set-Content -Path $sshd_config_file

# Change subsystem line for ssh
$line = Get-Content $sshd_config_file | Select-String "Subsystem        sftp" | Select-Object -ExpandProperty Line

if ($line -eq $null) {
  lwrite("$mtime Subsystem line not found")
} else {
  lwrite("$mtime Replacing subsystem line in sshd_config file")
  $content = Get-Content $sshd_config_file
  $content | ForEach-Object {$_ -replace $line, "Subsystem powershell c:/progra~1/powershell/7/pwsh.exe -sshs -nologo"} | Set-Content $sshd_config_file
}

# Set default shell to Windows Powershell
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force

# Restart OpenSSH Service
lwrite("$mtime Restart sshd service")
Restart-Service sshd

$mtime = Get-Date
lwrite ("$mtime End of bootstrap script")
