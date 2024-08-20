# Beginning of bootstrap script
# This script bootstraps the Windows system and is loaded through Azure user data
# VM Extension

# Set logfile and function for writing logfile
$logfile = "C:\Terraform\bootstrap_log.log"
Function lwrite {
    Param ([string]$logstring)
    Add-Content $logfile -value $logstring
}

$mtime = Get-Date
lwrite("$mtime Starting bootstrap powershell script")

# Check the domain join variable passed in from Terraform
# If it is set to 1, then set a domain_join boolean to True
$jd = "${join_domain}"
$mtime = Get-Date
if ( $jd -eq 1 ) {
  lwrite("$mtime Join Domain is set to true")
  lwrite("$mtime WinRM username is ${winrm_username}")
} else {
  lwrite("$mtime Join Domain is set to false")
}

### Force Enabling WinRM and skip profile check
$mtime = Get-Date
lwrite("$mtime Enabling PSRemoting SkipNetworkProfileCheck")
Enable-PSRemoting -SkipNetworkProfileCheck -Force 

$mtime = Get-Date
lwrite("$mtime Set Execution Policy Unrestricted")
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force

$Cert = New-SelfSignedCertificate -DnsName $RemoteHostName, $ComputerName `
    -CertStoreLocation "cert:\LocalMachine\My" `
    -FriendlyName "Test WinRM Cert"

$Cert | Out-String

$Thumbprint = $Cert.Thumbprint

Write-Host "Enable HTTPS in WinRM"
$WinRmHttps = "@{Hostname=`"$RemoteHostName`"; CertificateThumbprint=`"$Thumbprint`"}"
winrm create winrm/config/Listener?Address=*+Transport=HTTPS $WinRmHttps

Write-Host "Set Basic Auth in WinRM"
$WinRmBasic = "@{Basic=`"true`"}"
winrm set winrm/config/service/Auth $WinRmBasic

Write-Host "Open Firewall Ports"
netsh advfirewall firewall add rule name="Windows Remote Management (HTTP-In)" dir=in action=allow protocol=TCP localport=5985
netsh advfirewall firewall add rule name="Windows Remote Management (HTTPS-In)" dir=in action=allow protocol=TCP localport=5986

### Force Enabling WinRM and skip profile check
Enable-PSRemoting -SkipNetworkProfileCheck -Force

# Set Trusted Hosts * for WinRM HTTPS
Set-Item -Force wsman:\localhost\client\trustedhosts *

# Set the DNS to be the domain controller only if domain joined 
if ( $jd -eq 1 ) {
  $myindex = Get-Netadapter -Name "Ethernet" | Select-Object -ExpandProperty IfIndex
  Set-DNSClientServerAddress -InterfaceIndex $myindex -ServerAddresses "${dc_ip}"
  lwrite("$mtime Set DNS to be DC since joined to the domain")
}

# Beginning of script contents
$script_contents = '
$mydomain = "${ad_domain}"
$logfile = "C:\Terraform\domain_join_log.log"
Function lwrite {
    Param ([string]$logstring)
    Add-Content $logfile -value $logstring
}
$mtime = Get-Date
lwrite("$mtime Starting script")
# Test if actually joined to the domain
if ((gwmi win32_computersystem).partofdomain -eq $true) {
  $mtime = Get-Date
  lwrite("$mtime Joined to a domain")
  
  ### set the WinRM DA password
  $userpassword = "${winrm_password}"
  lwrite("$mtime WinRM password: $userpassword")

  # Get the domain first part
  $splits = "${ad_domain}".split(".")

  # this prefix
  $prefix = $splits[0]

  ### Set the DA Username
  $username = $prefix.ToUpper() + "\" + "${winrm_username}"

  # set the secure string password
  $secstringpassword = ConvertTo-SecureString $userpassword -AsPlainText -Force

  # Create a credential object
  $credObject = New-Object System.Management.Automation.PSCredential ($username, $secstringpassword)

  # Domain Controller IP
  $ad_ip = "${dc_ip}"
  lwrite("$mtime AD IP:  $ad_ip")

  # The remote WinRM username for checking DA ability to authenticate
  $winrm_check = $username
  lwrite("$mtime WinRM username: $winrm_check")

  # Invoke a remote command using WinRM
  $mtime = Get-Date
  lwrite("$mtime Testing WinRM Authentication for Invoke-Command of whoami")
  $op = Invoke-Command -ComputerName $ad_ip -ScriptBlock { try { whoami} catch { return $_ } } -credential $credObject

  if ( $op -Contains $winrm_check ){

    $mtime = Get-Date
    lwrite("$mtime Successful WinRM Invoke-Command!")

    if ( ${auto_logon_domain_user} ) {

      mwrite("$mtime Auto Logon domain user setting is true") 
      ### Set registry entry for Winlogon and automatically log in user with domain user credentials
      $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
      $DefaultUsername = "${endpoint_ad_user}"
      $DefaultPassword = "${endpoint_ad_password}"
      $DefaultDomainName = "${ad_domain}".ToUpper()

      $mtime = Get-Date
      lwrite("$mtime Setting Winlogon registry for $DefaultUsername")
      Set-ItemProperty $Regpath "AutoAdminLogon" -Value "1" -type String
      Set-ItemProperty $Regpath "DefaultUsername" -Value "$DefaultUsername" -type String
      Set-ItemProperty $Regpath "DefaultPassword" -Value "$DefaultPassword" -type String
      Set-ItemProperty $Regpath "DefaultDomainName" -Value "$DefaultDomainName" -type String
      mwrite("$mtime Set registry to auto logon domain user") 
      mwrite("$mtime Username $DefaultUsername") 
      mwrite("$mtime Password $DefaultPassword") 
      mwrite("$mtime Domain $DefaultDomainName") 
    }

    #Unregister the scheduled task
    $mtime = Get-Date
    lwrite("$mtime Unregister the scheduled task DomainJoin01")
    Unregister-ScheduledTask -TaskName DomainJoin01 -Confirm:$false

    $mtime = Get-Date
    #Uncomment below if you want to clean up everything
    #lwrite ("$mtime Removing ps scripts in C:\terraform")
    #Remove-Item C:\Terraform\*.ps1
    Restart-Computer
  }
} else {

  # In this case, we are not joined to the Domain
  # So we are going to use WinRM to join to the Domain
  $mtime = Get-Date
  lwrite("$mtime Not joined to AD Domain - attempting to join")
  
  ### set the WinRM DA password
  $userpassword = "${winrm_password}"
  lwrite("$mtime WinRM password: $userpassword")

  ## this prefix
  $splits = "${ad_domain}".split(".")

  ## Get first part
  $prefix = $splits[0]

  ### Set the DA Username
  $username = $prefix.ToUpper() + "\" + "${winrm_username}"
  lwrite("$mtime WinRM username: $username")

  # set the secure string password
  $secstringpassword = ConvertTo-SecureString $userpassword -AsPlainText -Force

  # Create a credential object
  $credObject = New-Object System.Management.Automation.PSCredential ($username, $secstringpassword)

  # Domain Controller IP
  $ad_ip = "${dc_ip}"
  lwrite("$mtime DC: $ad_ip")

  # The remote WinRM username for checking DA ability to authenticate
  $winrm_check = $username

  # Current hostname
  $chostname = $env:COMPUTERNAME

  # Invoke a remote command using WinRM
  $mtime = Get-Date

  lwrite("$mtime Testing WinRM Authentication for Invoke-Command of whoami")
  $op = Invoke-Command -ComputerName $ad_ip -ScriptBlock { try { whoami} catch { return $_ } } -credential $credObject

  if ( $op -Contains $winrm_check ){

    $mtime = Get-Date
    lwrite("$mtime Successful WinRM Invoke-Command for Domain Join section!")

    # Join this computer to the domain
    $mtime = Get-Date
    lwrite("$mtime Attempting to join the computer to the domain")
    lwrite("$mtime Computer:  $chostname")
    lwrite("$mtime Domain:  $mydomain")

    # Join domain over PSCredential object
    Add-Computer -ComputerName $chostname -DomainName $mydomain -Credential $credObject -Restart -Force
    $mtime = Get-Date
    lwrite("$mtime Joined to the domain and now rebooting")
  }
} 
$mtime = Get-Date
lwrite ("$mtime End of script")
'
# End of script contents

# Do this check because we only want to create this script if 
# configuration is set to join the domain
$mtime = Get-Date
lwrite ("$mtime Checking if domain join configuration is set to true")
if ( $jd -eq 1 ) {

  $mtime = Get-Date
  lwrite ("$mtime Domain join configuration is set to true")

  # Write a new script for AD Join and auto logon domain user (if applicable) 
  $mtime = Get-Date
  lwrite ("$mtime Creating script C:\Terraform\DomainJoin.ps1")
  Set-Content -Path "C:\Terraform\DomainJoin.ps1" -Value $script_contents

  # Create a schedule task to run this script once a minute
  $mtime = Get-Date
  lwrite ("$mtime Creating scheduled task to run the script once a minute")

  # Create a scheduled task action
  $sta = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -WindowStyle Hidden -command "C:\Terraform\DomainJoin.ps1"'

  # Create a schedule task trigger
  $stt = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionDuration (New-TimeSpan -Days 1) -RepetitionInterval (New-TimeSpan -Minutes 1)

  # Create a new scheduled task setting
  $sts = New-ScheduledTaskSettingsSet

  # Set it to Stop the existing instance (for proper startup after reboot)
  $sts.CimInstanceProperties.Item('MultipleInstances').Value = 3   # 3 corresponds to 'Stop the existing instance'

  # Register new scheduled task
  Register-ScheduledTask DomainJoin01 -Action $sta -Settings $sts -Trigger $stt -User "${admin_username}" -Password "${admin_password}"
} else {
  
  $mtime = Get-Date
  lwrite ("$mtime Domain join configuration is set to false")

}

$mtime = Get-Date
lwrite("$mtime Setting DNS resolver to public DNS")
$myindex = Get-Netadapter -Name "Ethernet" | Select-Object -ExpandProperty IfIndex
Set-DNSClientServerAddress -InterfaceIndex $myindex -ServerAddresses "8.8.8.8"

# Check if install_sysmon is true
$is = "${install_sysmon}"
$mtime = Get-Date
if ( $is -eq 1 ) {
  lwrite("$mtime Install sysmon is set to true")

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
      lwrite("$mtime Error downloading sysmon config")
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

} else {
  lwrite("$mtime Install sysmon is set to false")
}

###
# Always download PurpleSharp
###
if (Test-Path -Path "C:\tools") {
  lwrite("$mtime C:\tools exists")
} else {
  lwrite("$mtime Creating C:\tools")
  New-Item -Path "C:\tools" -ItemType Directory
}
# Test for PurpleSharp and download if necessary
if (Test-Path -Path "C:\tools\PurpleSharp.exe") {
  lwrite("$mtime C:\tools\PurpleSharp.exe exists")
} else {
  lwrite("$mtime Downloading PurpleSharp to C:\tools\PurpleSharp.exe")
  Invoke-WebRequest -Uri "https://github.com/mvelazc0/PurpleSharp/releases/download/v1.3/PurpleSharp_x64.exe" -OutFile "C:\tools\PurpleSharp.exe"
}

# Check if install_art is true
$art = "${install_art}"
$mtime = Get-Date
if ( $art -eq 1 ) {
  lwrite("$mtime Install atomic red team is set to true")

  # Set AV exclusion path so red team tools can run
  Set-MpPreference -ExclusionPath "C:\Tools"
  lwrite("$mtime Set AV Exclusion path to Tools")

  # Get atomic red team (ART)
  $mtime = Get-Date
  lwrite("$mtime Downloading Atomic Red Team")
  $MaxAttempts = 5
  $TimeoutSeconds = 30
  $Attempt = 0

  $mtime = Get-Date
  if (Test-Path -Path "C:\Tools\atomic-red-team-master.zip") {
    lwrite("$mtime C:\Tools\atomic-red-team-master.zip exists")
  } else {
    while ($Attempt -lt $MaxAttempts) {
      $Attempt += 1
      $mtime = Get-Date
      lwrite("$mtime Attempt: $Attempt")
      try {
        Invoke-WebRequest -Uri "https://github.com/redcanaryco/atomic-red-team/archive/refs/heads/master.zip" -OutFile "C:\Tools\atomic-red-team-master.zip" -TimeoutSec $TimeoutSeconds
        $mtime = Get-Date
        lwrite("$mtime Successful")
        break
      } catch {
        if ($_.Exception.GetType().Name -eq "WebException" -and $_.Exception.Status -eq "Timeout") {
          $mtime = Get-Date
          lwrite("$mtime Connection timed out")
        } else {
          $mtime = Get-Date
          lwrite("$mtime An unexpected error occurred:")
          lwrite($_.Exception.Message)
          break
        }
      }
    }

    if ($Attempt -eq $MaxAttempts) {
      $mtime = Get-Date
      lwrite("$mtime Reached maximum number of attempts")
    }

  }

  if (Test-Path -Path "C:\Tools\atomic-red-team-master.zip") {
    $mtime = Get-Date
    lwrite("$mtime Expanding atomic red team zip archive")
    Expand-Archive -Force -LiteralPath 'C:\Tools\atomic-red-team-master.zip' -DestinationPath 'C:\Tools\atomic-red-team-master'
  } else {
    lwrite("$mtime Something went wrong - atomic red team zip not found")
  }

  # Install invoke-atomicredteam Module
  $mtime = Get-Date
  lwrite("$mtime Installing Module invoke-atomicredteam")
  Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
  Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
  Install-Module -Name invoke-atomicredteam,powershell-yaml -Scope AllUsers -Force
  IEX (IWR 'https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1' -UseBasicParsing);
  Install-AtomicRedTeam -getAtomics

} else {
  lwrite("$mtime Install atomic red team is set to false")
}

$mtime = Get-Date
lwrite("$mtime Install Powershell Core")
iwr -Uri "https://github.com/PowerShell/PowerShell/releases/download/v7.4.1/PowerShell-7.4.1-win-x64.msi" -Outfile "C:\terraform\Powershell-7.4.1-win-x64.msi"
msiexec.exe /package "C:\terraform\PowerShell-7.4.1-win-x64.msi" /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1 USE_MU=1 ENABLE_MU=1 ADD_PATH=1

# OpenSSH Server
$mtime = Get-Date
lwrite("$mtime Install of OpenSSH Server")
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH*'
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Start OpenSSH service
$mtime = Get-Date
lwrite("$mtime Start SSH Server service")
Start-Service sshd

# Set startup automatic
Set-Service -Name sshd -StartupType 'Automatic'

# Firewall rules confirmed
$mtime = Get-Date
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

$mtime = Get-Date
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
$mtime = Get-Date
lwrite("$mtime Restart sshd service")
Restart-Service sshd

# If Join Domain is True, set the DNS server back to dc_ip
if ( $jd -eq 1 ) {
  $myindex = Get-Netadapter -Name "Ethernet" | Select-Object -ExpandProperty IfIndex
  Set-DNSClientServerAddress -InterfaceIndex $myindex -ServerAddresses "${dc_ip}"
  lwrite("$mtime Join Domain is true, setting DNS server to DC:  ${dc_ip} ")
}

$mtime = Get-Date
lwrite("$mtime End bootstrap powershell script")
