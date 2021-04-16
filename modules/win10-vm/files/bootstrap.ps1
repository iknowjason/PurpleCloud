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

  ### Set the DA Username
  $username = "${prefix}".ToUpper() + "\" + "${winrm_username}"

  # set the secure string password
  $secstringpassword = ConvertTo-SecureString $userpassword -AsPlainText -Force

  # Create a credential object
  $credObject = New-Object System.Management.Automation.PSCredential ($username, $secstringpassword)

  # Domain Controller IP
  $ad_ip = "${dc_ip}"

  # The remote WinRM username for checking DA ability to authenticate
  $winrm_check = $username

  # Invoke a remote command using WinRM
  $mtime = Get-Date
  lwrite("$mtime Testing WinRM Authentication for Invoke-Command of whoami")
  $op = Invoke-Command -ComputerName $ad_ip -ScriptBlock { try { whoami} catch { return $_ } } -credential $credObject

  if ( $op -Contains $winrm_check ){
    $mtime = Get-Date
    lwrite("$mtime Successful WinRM Invoke-Command!")

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
  $mtime = Get-Date
  lwrite("$mtime Not joined to AD Domain")

  # In this case, we are not joined to the Domain
  # So we are going to use WinRM to join to the Domain
  
  ### set the WinRM DA password
  $userpassword = "${winrm_password}"

  ### Set the DA Username
  $username = "${prefix}".ToUpper() + "\" + "${winrm_username}"

  # set the secure string password
  $secstringpassword = ConvertTo-SecureString $userpassword -AsPlainText -Force

  # Create a credential object
  $credObject = New-Object System.Management.Automation.PSCredential ($username, $secstringpassword)

  # Domain Controller IP
  $ad_ip = "${dc_ip}"

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

$mtime = Get-Date
lwrite("$mtime End bootstrap powershell script")
