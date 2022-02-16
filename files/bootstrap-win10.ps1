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

  # Download Sysmon for HELK
  $mtime = Get-Date
  lwrite("$mtime Download Sysmon")
  (New-Object System.Net.WebClient).DownloadFile('https://github.com/iknowjason/BlueTools/blob/main/Sysmon.zip?raw=true', 'C:\terraform\Sysmon.zip')

  $mtime = Get-Date
  lwrite("$mtime Download SwiftOnSecurity sysmon config for HELK")
  (New-Object System.Net.WebClient).DownloadFile('https://github.com/iknowjason/BlueTools/blob/main/configs-pc.zip?raw=true', 'C:\terraform\configs.zip')

  # Expand the Sysmon zip archive
  $mtime = Get-Date
  lwrite("$mtime Expand the sysmon zip file")
  Expand-Archive -LiteralPath 'C:\terraform\Sysmon.zip' -DestinationPath 'C:\terraform\Sysmon'

  # Expand the configs zip archive
  $mtime = Get-Date
  lwrite("$mtime Expand the configs zip file")
  Expand-Archive -LiteralPath 'C:\terraform\configs.zip' -DestinationPath 'C:\terraform\configs'

  # Copy the Sysmon configuration for SwiftOnSecurity to destination Sysmon folder
  $mtime = Get-Date
  lwrite("$mtime Copy the Sysmon configuration for SwiftOnSecurity to destination Sysmon folder")
  Copy-Item "C:\terraform\configs\configs-pc\sysmonconfig-export.xml" -Destination "C:\terraform\Sysmon"

  # Install Sysmon for HELK
  $mtime = Get-Date
  lwrite("$mtime Install Sysmon for HELK")
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

  $mtime = Get-Date
  lwrite("$mtime Download Elastic and Atomic Red Team (ART)")

  (New-Object System.Net.WebClient).DownloadFile('https://github.com/elastic/detection-rules/archive/main.zip', 'C:\terraform\Elastic_Detections.zip')

  (New-Object System.Net.WebClient).DownloadFile('https://github.com/redcanaryco/atomic-red-team/archive/refs/heads/master.zip', 'C:\terraform\ART.zip')

  (New-Object System.Net.WebClient).DownloadFile('https://github.com/NextronSystems/APTSimulator/releases/download/v0.8.0/APTSimulator_pw_apt.zip', 'C:\terraform\APTSimulator.zip')

  $mtime = Get-Date
  lwrite("$mtime Expand Elastic and ART Repos")

  Expand-Archive -LiteralPath 'C:\terraform\Elastic_Detections.zip' -DestinationPath 'C:\terraform\Elastic_Detections'
  Expand-Archive -LiteralPath 'C:\terraform\ART.zip' -DestinationPath 'C:\terraform\ART'

  $mtime = Get-Date
  lwrite("$mtime Download and install Python 3.8.6")

  ### Download Python 3.8
  (New-Object System.Net.WebClient).DownloadFile('https://www.python.org/ftp/python/3.8.6/python-3.8.6-amd64.exe','C:\terraform\python-3.8.6-amd64.exe')

  ### Quiet install of Python
  C:\terraform\python-3.8.6-amd64.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0

  # Local Administrator
  #$admin = "${admin_username}"

  ### Add Path environment variable
  $pythonRootFolder = "C:\Users\" + "${admin_username}" + "\AppData\Local\Programs\Python\Python38"
  $pythonScriptsFolder = "C:\Users\" + "${admin_username}" + "\AppData\Local\Programs\Python\Python38\Scripts"
  $path = [System.Environment]::GetEnvironmentVariable('path', 'user')
  $path += ";$pythonRootFolder"
  $path += ";$pythonScriptsFolder;"
  [System.Environment]::SetEnvironmentVariable('path', $path, 'user')

  $mtime = Get-Date
  lwrite("$mtime pip install requirements for Elastic")
  #### Requirements installation
  pip install -r C:\terraform\Elastic_Detections\detection-rules-main\requirements.txt

  $mtime = Get-Date
  lwrite("$mtime Install NuGet for ART")
  Set-Location -Path "C:\"
  Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

  $script_contents = '
if (Get-Module -Name "Invoke-AtomicRedTeam") {
  Write-Host "Invoke-AtomicRedTeam already installed"
} else { 
  Write-Host "Invoke-AtomicRedTeam not installed"
  IEX (New-Object Net.WebClient).DownloadString("https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1")
  Install-AtomicRedTeam -Force
}
'
  lwrite("Create Powershell profile to import invoke-atomicredteam with each powershell session")
  Set-Content -Path C:\Users\${admin_username}\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1 -Value $script_contents 

} else {
  lwrite("$mtime Install atomic red team is set to false")
}

# Check if install_agent is true - send logs to helk + enable velociraptor 
$ia = "${install_agent}"
$mtime = Get-Date
if ( $ia -eq 1 ) {
  lwrite("$mtime install_agent is set to true")

  lwrite("$mtime Downloading velociraptor client")
  # Download velociraptor client windows MSI 
  (New-Object System.Net.WebClient).DownloadFile('https://github.com/iknowjason/BlueTools/blob/main/velociraptor-v0.5.6-windows-amd64.msi.zip?raw=true', 'C:\terraform\velociraptor-windows-msi.zip')

  # Expand the Velociraptor zip archive
  $mtime = Get-Date
  lwrite("$mtime Expanding the velociraptor zip file")
  Expand-Archive -LiteralPath 'C:\terraform\velociraptor-windows-msi.zip' -DestinationPath 'C:\terraform\velociraptor-windows-msi'

  lwrite("$mtime Creating Program Files Velociraptor Directory")
  New-Item "C:\Program Files\Velociraptor" -ItemType Directory

  # Install the velociraptor MSI with quiet mode 
  $mtime = Get-Date
  lwrite("$mtime Install velociraptor with quiet mode")
  msiexec.exe /I C:\terraform\velociraptor-windows-msi\velociraptor-v0.5.6-windows-amd64.msi /quiet

  # Download winlogbeat for HELK
  $mtime = Get-Date
  lwrite("$mtime Download Winlogbeat for HELK")
  (New-Object System.Net.WebClient).DownloadFile('https://github.com/iknowjason/BlueTools/blob/main/winlogbeat-7.9.2-windows-x86_64.zip?raw=true', 'C:\terraform\winlogbeat.zip')

  # Download configuration zip file, which contains SwiftOnSecurity sysmon config and winlogbeat config
  $mtime = Get-Date
  if (-not(Test-Path -Path "C:\terraform\configs.zip" -PathType Leaf)) {
    try {
      lwrite("$mtime Download SwiftOnSecurity sysmon config for HELK")
      (New-Object System.Net.WebClient).DownloadFile('https://github.com/iknowjason/BlueTools/blob/main/configs-pc.zip?raw=true', 'C:\terraform\configs.zip')

      # Expand the configs zip archive
      $mtime = Get-Date
      lwrite("$mtime Expand the configs zip file")
      Expand-Archive -LiteralPath 'C:\terraform\configs.zip' -DestinationPath 'C:\terraform\configs'
    } catch {
      Write-Host("Error downloading and unzipping")
    }
  }

  # Expand the winlogbeat zip archive
  $mtime = Get-Date
  lwrite("$mtime Expand the winlogbeat zip archive")
  Expand-Archive -LiteralPath 'C:\terraform\winlogbeat.zip' -DestinationPath 'C:\terraform\Winlogbeat'

  # Copy the Winlogbeat HELK configuration to destination Winlogbeat folder
  $mtime = Get-Date
  lwrite("$mtime Changing winlogbeat.yml file to use the helk IP ${helk_ip}")
  (Get-Content c:\terraform\configs\configs-pc\winlogbeat.yml) -replace "10.100.1.5", "${helk_ip}" | Set-Content C:\terraform\configs\configs-pc\winlogbeat.yml
  lwrite("$mtime Copy the Winlogbeat HELK configuration to destination Winlogbeat folder")
  Copy-Item "C:\terraform\configs\configs-pc\winlogbeat.yml" -Destination "C:\terraform\Winlogbeat\winlogbeat-7.9.2-windows-x86_64"

  # Copy the Winlogbeat folder to C:\ProgramData
  $mtime = Get-Date
  lwrite("$mtime Copy the Winlogbeat folder to C:\ProgramData")
  Copy-Item "C:\terraform\Winlogbeat\winlogbeat-7.9.2-windows-x86_64" -Destination "C:\ProgramData\Winlogbeat" -Recurse

  # Install thn Winlogbeat folder
  $mtime = Get-Date
  lwrite("$mtime Install the Winlogbeat service using included powershell script")
  C:\ProgramData\Winlogbeat\install-service-winlogbeat.ps1

  # Start the Winlogbeat service
  $mtime = Get-Date
  lwrite("$mtime Start the Winlogbeat service")
  start-service winlogbeat

} else {
  lwrite("$mtime install_agent is set to false")
}

$mtime = Get-Date
lwrite("$mtime End bootstrap powershell script")
