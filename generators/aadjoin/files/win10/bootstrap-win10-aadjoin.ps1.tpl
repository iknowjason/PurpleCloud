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

$mtime = Get-Date
lwrite("$mtime Setting DNS resolver to public DNS")
$myindex = Get-Netadapter -Name "Ethernet" | Select-Object -ExpandProperty IfIndex
Set-DNSClientServerAddress -InterfaceIndex $myindex -ServerAddresses "8.8.8.8"

$ComputerName = hostname
lwrite("$mtime ComputerName: $ComputerName")

# Set NLA disabled for RDP
lwrite("$mtime Disabling NLA to allow remote RDP for Azure AD Login")
(Get-WmiObject -class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -ComputerName $ComputerName -Filter "TerminalName='RDP-tcp'").SetUserAuthenticationRequired(0)

$mtime = Get-Date
lwrite("$mtime End bootstrap powershell script")
