# Beginning of bootstrap script
# This script bootstraps the Windows system and is loaded through Azure user data
# VM Extension

# Set logfile and function for writing logfile
$logfile = "C:\Terraform\user_data.log"
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

# Set the DNS to be the domain controller only if domain joined 
if ( $jd -eq 1 ) {
  $myindex = Get-Netadapter -Name "Ethernet" | Select-Object -ExpandProperty IfIndex
  Set-DNSClientServerAddress -InterfaceIndex $myindex -ServerAddresses "${dc_ip}"
  lwrite("$mtime Set DNS to be DC since joined to the domain")
}

# Beginning of script contents
$script_contents = '
$mydomain = "${ad_domain}"
$logfile = "C:\Terraform\user_data.log"
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
    lwrite("$mtime Unregister the scheduled task WinlogonUser01")
    Unregister-ScheduledTask -TaskName WinlogonUser01 -Confirm:$false

    $mtime = Get-Date
    lwrite ("$mtime Removing ps scripts in C:\terraform")
    Remove-Item C:\Terraform\*.ps1
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

  # Write a new script for editing WinLogon registry entries 
  $mtime = Get-Date
  lwrite ("$mtime Creating script C:\Terraform\WinLogon.ps1")
  Set-Content -Path "C:\Terraform\Winlogon.ps1" -Value $script_contents

  # Create a schedule task to run this script once a minute
  $mtime = Get-Date
  lwrite ("$mtime Creating scheduled task to run the script once a minute")

  # Create a scheduled task action
  $sta = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -WindowStyle Hidden -command "C:\Terraform\Winlogon.ps1"'

  # Create a schedule task trigger
  $stt = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionDuration (New-TimeSpan -Days 1) -RepetitionInterval (New-TimeSpan -Minutes 1)

  # Create a new scheduled task setting
  $sts = New-ScheduledTaskSettingsSet

  # Set it to Stop the existing instance (for proper startup after reboot)
  $sts.CimInstanceProperties.Item('MultipleInstances').Value = 3   # 3 corresponds to 'Stop the existing instance'

  # Register new scheduled task
  Register-ScheduledTask WinlogonUser01 -Action $sta -Settings $sts -Trigger $stt -User "${admin_username}" -Password "${admin_password}"
} else {
  
  $mtime = Get-Date
  lwrite ("$mtime Domain join configuration is set to false")

}

# Check if install_sysmon is true
$is = "${install_sysmon}"
$mtime = Get-Date
if ( $is -eq 1 ) {
  lwrite("$mtime Install sysmon is set to true")

  $mtime = Get-Date
  lwrite("$mtime Setting DNS resolver to public DNS")
  $myindex = Get-Netadapter -Name "Ethernet" | Select-Object -ExpandProperty IfIndex
  Set-DNSClientServerAddress -InterfaceIndex $myindex -ServerAddresses "8.8.8.8"

  # Download Sysmon
  $mtime = Get-Date
  lwrite("$mtime Download Sysmon")
  (New-Object System.Net.WebClient).DownloadFile('https://${storage_acct_s}.blob.core.windows.net/${storage_container_s}/${sysmon_zip_s}', 'C:\terraform\Sysmon.zip')

  $mtime = Get-Date
  lwrite("$mtime Download SwiftOnSecurity sysmon config")
  (New-Object System.Net.WebClient).DownloadFile('https://github.com/iknowjason/BlueTools/blob/main/configs-pc.zip?raw=true', 'C:\terraform\configs.zip')

  # Download Sysmon config xml
  $mtime = Get-Date
  if (-not(Test-Path -Path "C:\terraform\sysmonconfig-export.xml" -PathType Leaf)) {
    try {
      lwrite("$mtime Download Sysmon config")
      (New-Object System.Net.WebClient).DownloadFile('https://${storage_acct_s}.blob.core.windows.net/${storage_container_s}/${sysmon_config_s}', 'C:\terraform\sysmonconfig-export.xml')
    } catch {
      Write-Host("Error downloading and unzipping")
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

  # If Join Domain is True, set the DNS server back to dc_ip
  if ( $jd -eq 1 ) {
    $myindex = Get-Netadapter -Name "Ethernet" | Select-Object -ExpandProperty IfIndex
    Set-DNSClientServerAddress -InterfaceIndex $myindex -ServerAddresses "${dc_ip}"
    lwrite("$mtime Join Domain is true, setting DNS server to DC:  ${dc_ip} ")
  }

} else {
  lwrite("$mtime Install sysmon is set to false")
}

# Check if install_art is true
$art = "${install_art}"
$mtime = Get-Date
if ( $art -eq 1 ) {
  lwrite("$mtime Install atomic red team is set to true")

  # Set AV exclusion path so red team tools can run
  Set-MpPreference -ExclusionPath "C:\Tools"
  lwrite("$mtime Set AV Exclusion path to Tools")

  $mtime = Get-Date
  lwrite("$mtime Download Elastic Detection Rules")

  (New-Object System.Net.WebClient).DownloadFile('https://github.com/elastic/detection-rules/archive/main.zip', 'C:\terraform\Elastic_Detections.zip')

  (New-Object System.Net.WebClient).DownloadFile('https://github.com/NextronSystems/APTSimulator/releases/download/v0.8.0/APTSimulator_pw_apt.zip', 'C:\terraform\APTSimulator.zip')

  $mtime = Get-Date
  lwrite("$mtime Expand Elastic Detection Rules zip")

  Expand-Archive -Force -LiteralPath 'C:\terraform\Elastic_Detections.zip' -DestinationPath 'C:\terraform\Elastic_Detections'

  $mtime = Get-Date
  lwrite("$mtime Download and install Python 3.8.6")

  ### Download Python 3.8
  (New-Object System.Net.WebClient).DownloadFile('https://www.python.org/ftp/python/3.8.6/python-3.8.6-amd64.exe','C:\terraform\python-3.8.6-amd64.exe')

  ### Quiet install of Python
  C:\terraform\python-3.8.6-amd64.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0

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
          lwrite("$mtime Connection timed out. Retrying...")
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

  #### Detection Rules Requirements installation
  $mtime = Get-Date
  lwrite("$mtime before pip install requirements for Elastic")
  pip install -r C:\terraform\Elastic_Detections\detection-rules-main\requirements.txt
  lwrite("$mtime after pip install requirements for Elastic")

} else {
  lwrite("$mtime Install atomic red team is set to false")
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

$mtime = Get-Date
lwrite("$mtime End bootstrap powershell script")
