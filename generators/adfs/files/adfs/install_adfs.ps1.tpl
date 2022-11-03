# This script install ADFS service

# the AD Domain
$mydomain = "${ad_domain}"
$myhost = "${hostname}"
$fqdn = $myhost + "." + $mydomain

$logfile = "C:\Terraform\install_adfs.log"
Function lwrite {
    Param ([string]$logstring)
    Add-Content $logfile -value $logstring
}

$mtime = Get-Date
lwrite("$mtime Starting script")

# Test if actually joined to the domain
if ((gwmi win32_computersystem).partofdomain -eq $true) {
  $mtime = Get-Date
  lwrite("$mtime Joined to domain")

  $mtime = Get-Date
  lwrite("$mtime Installing nuget package provider")
  Install-PackageProvider nuget -force

  $mtime = Get-Date
  lwrite("$mtime Installing PSPKI module")
  Install-Module -Name PSPKI -Force

  $mtime = Get-Date
  lwrite("$mtime Importing PSPKI into current environment")
  Import-Module -Name PSPKI

  $mtime = Get-Date
  lwrite("$mtime Generating Certificate")
  $selfSignedCert = New-SelfSignedCertificateEx `
    -Subject "CN=$fqdn" `
    -ProviderName "Microsoft Enhanced RSA and AES Cryptographic Provider" `
    -KeyLength 2048 -FriendlyName 'ADFS SelfSigned' -SignatureAlgorithm sha256 `
    -EKU "Server Authentication", "Client authentication" `
    -KeyUsage "KeyEncipherment, DigitalSignature" `
    -Exportable -StoreLocation "LocalMachine"
  $certThumbprint = $selfSignedCert.Thumbprint

  lwrite("$mtime Self-Signed certificate thumbprint: $certThumbprint")

  $mtime = Get-Date
  lwrite("$mtime Installing ADFS-Federation Windows Feature if needed")
  $retval = Get-WindowsFeature -Name ADFS-Federation
  if ($retval.InstallState -Like "Installed") {
    lwrite("$mtime Already installed")
  } else {
    lwrite("$mtime Installing ADFS-Federation")
    Install-WindowsFeature -IncludeManagementTools -Name ADFS-Federation
  }

  # Get the domain first part
  $splits = "${ad_domain}".split(".")

  # this prefix
  $prefix = $splits[0]

  $svc_username = $prefix.ToUpper() + "\" + "${winrm_username}"
  $svc_password = "${winrm_password}"
  $securesvcpassword =  ConvertTo-SecureString $svc_password -AsPlainText -Force
  $svcCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($svc_username, $securesvcpassword) 

  $admin_username = "${admin_username}"
  $admin_password = "${admin_password}"
  $secureadminpassword =  ConvertTo-SecureString $admin_password -AsPlainText -Force
  $adminCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($admin_username, $secureadminpassword) 

  $mtime = Get-Date
  lwrite("$mtime Running Install-AdfsFarm")
  Import-Module ADFS
  Install-AdfsFarm -CertificateThumbprint $certThumbprint -FederationServiceName $fqdn -ServiceAccountCredential $svcCred -Credential $svcCred -OverWriteConfiguration

  # Set properties
  set-AdfsProperties -EnableIdPInitiatedSignonPage $true
  Set-AdfsProperties -Auditlevel verbose
  Set-AdfsProperties -LogLevel ((Get-AdfsProperties).LogLevel+'SuccessAudits','FailureAudits')

  # Customize Web Content 
  Set-AdfsGlobalWebContent -CompanyName "ADFS Login"

  # Restart the service
  Restart-Service -Name adfssrv

  & auditpol.exe /set /subcategory:"Application Generated" /failure:enable /success:enable

  #Unregister the scheduled job
  $mtime = Get-Date
  lwrite("$mtime Unregister the scheduled task InstallADFS")
  Unregister-ScheduledJob -Name "InstallADFS"

} else {
  $mtime = Get-Date
  lwrite("$mtime Not Joined to domain")
}
