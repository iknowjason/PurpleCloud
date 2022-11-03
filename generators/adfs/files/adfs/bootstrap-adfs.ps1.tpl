# Beginning of bootstrap script

# Set logfile and function for writing logfile
$logfile = "C:\Terraform\bootstrap.log"
Function lwrite {
    Param ([string]$logstring)
    Add-Content $logfile -value $logstring
}

$mtime = Get-Date
lwrite("$mtime Start bootstrap powershell script")

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

# Download the script for install adfs 
$mtime = Get-Date
lwrite("$mtime Download install_adfs.ps1")

$counter = 1
$success = $false
do {
  lwrite("$mtime Looping $counter")

  if (Test-Path -Path "C:\terraform\domain_join.ps1" -PathType leaf) {
    lwrite("$mtime Script already downloaded")
    $success = $true
  } else {
    lwrite("$mtime Downloading script")
    try {
      (New-Object System.Net.WebClient).DownloadFile('https://${storage_acct_s}.blob.core.windows.net/${storage_container_s}/${install_adfs_s}', 'C:\terraform\${install_adfs_s}')
      $success = $true
    } catch {
      lwrite("$mtime Error downloading script: ", $_)
    }

    Start-Sleep -Seconds 15
  }
  $counter++
} until ( ($success -eq $true) -or ($counter -eq 5) )

# Download domain_join script only if True
# Configure scheduled task for domain_join script only if True
$mtime = Get-Date
lwrite ("$mtime Checking if domain join configuration is set to true")
if ( $jd -eq 1 ) {

  $mtime = Get-Date
  lwrite ("$mtime Domain join configuration is set to true")

  # Download the script for domain join 
  $mtime = Get-Date
  lwrite("$mtime Download domain_join.ps1")

  $counter = 1
  $success = $false
  do {
    lwrite("$mtime Looping $counter")
  
    if (Test-Path -Path "C:\terraform\domain_join.ps1" -PathType leaf) {
      lwrite("$mtime Script already downloaded")
      $success = $true
    } else {
      lwrite("$mtime Downloading script")
      try {
        (New-Object System.Net.WebClient).DownloadFile('https://${storage_acct_s}.blob.core.windows.net/${storage_container_s}/${domain_join_s}', 'C:\terraform\${domain_join_s}') 
        $success = $true
      } catch {
        lwrite("$mtime Error downloading script: ", $_)
      }

      Start-Sleep -Seconds 15
    }
    $counter++
  } until ( ($success -eq $true) -or ($counter -eq 5) )

  # Create a Pwsh Scheduled Job to run domain join script once a minute
  $mtime = Get-Date
  lwrite ("$mtime Creating scheduled job to run the script once a minute")
  $secstringpassword = ConvertTo-SecureString "${admin_password}" -AlPlainText -Force
  $credObject = New-Object System.Management.Automation.PSCredential ("${admin_username}", $secstringpassword)
  $TimeSpan = New-TimeSpan -Minutes 1 
  $AtStartup = New-JobTrigger -AtStartup
  Register-ScheduledJob -Name "DomainJoin" -Trigger $AtStartup -Credential $credObject -RunEvery $TimeSpan -FilePath "C:\terraform\domain_join.ps1"

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
  Expand-Archive -LiteralPath 'C:\terraform\Sysmon.zip' -DestinationPath 'C:\terraform\Sysmon'

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

$mtime = Get-Date
lwrite("$mtime Register Scheduled Job for install adfs script")
Register-ScheduledJob -Name "InstallADFS" -Trigger $AtStartup -Credential $credObject -RunEvery $TimeSpan -FilePath "C:\terraform\${install_adfs_s}"

$mtime = Get-Date
lwrite("$mtime End bootstrap powershell script")
