
# the AD Domain
$mydomain = "${ad_domain}"

$logfile = "C:\Terraform\domain_join.log"
Function lwrite {
    Param ([string]$logstring)
    Add-Content $logfile -value $logstring
}

$mtime = Get-Date
lwrite("$mtime Starting script")

# Set the DNS to be the domain controller only if domain joined
if ( $jd -eq 1 ) {
  $myindex = Get-Netadapter -Name "Ethernet" | Select-Object -ExpandProperty IfIndex
  Set-DNSClientServerAddress -InterfaceIndex $myindex -ServerAddresses "${dc_ip}"
  lwrite("$mtime Set DNS to be DC since joined to the domain")
}

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

    #Unregister the scheduled job 
    $mtime = Get-Date
    lwrite("$mtime Unregister the scheduled task DomainJoin01")
    Unregister-ScheduledJob -Name "DomainJoin"

    #$mtime = Get-Date
    #lwrite ("$mtime Removing ps scripts in C:\terraform")
    #Remove-Item C:\Terraform\*.ps1
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
