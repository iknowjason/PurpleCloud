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

# Beginning of script contents
$script_contents = '

$logfile = "C:\Terraform\user_data.log"

Function lwrite {
    Param ([string]$logstring)
    Add-Content $logfile -value $logstring
}

$mtime = Get-Date
lwrite("$mtime Starting script")

$forest = "rtcfingroup.com"
$myou = "OU=Finance,ou=users,dc=rtcfingroup,dc=com"

$mtime = Get-Date
lwrite ("$mtime Starting to verify AD forest")

$op = Get-WMIObject Win32_NTDomain | Select -ExpandProperty DnsForestName

if ( $op -Contains $forest ){
    $mtime = Get-Date
    lwrite ("$mtime Verified AD forest is set to $forest")

    $mtime = Get-Date
    lwrite ("$mtime Checking to add Domain Users to $forest AD Domain")
    $ADUsers = @()

    #User Lars Borgerson
    $user1 = @{FirstName = "Lars"; LastName = "Borgerson"; usernm = "lars"; ou = $myou; pcred = "Password123"}
    $ADUsers += $user1

    #User Olivia Odinsdottir (Domain Administrator)
    $user2 = @{FirstName = "Olivia"; LastName = "Odinsdottir"; usernm = "olivia"; ou = $myou; pcred = "Password123"}
    $ADUsers += $user2

    #User Liem Anderson
    $user3 = @{FirstName = "Liem"; LastName = "Anderson"; usernm = "liem"; ou = $myou; pcred = "Password123"}
    $ADUsers += $user3

    #User John Nilsson
    $user4 = @{FirstName = "John"; LastName = "Nilsson"; usernm = "john"; ou = $myou; pcred = "Password123"}
    $ADUsers += $user4

    #User Jason Lindqvist (Domain Administrator for WinRM)
    $user5 = @{FirstName = "Jason"; LastName = "Lindqvist"; usernm = "jason"; ou = $myou; pcred = "Password123"}
    $ADUsers += $user5

    foreach ($User in $ADUsers)
    {
        $Username = $User.usernm
        $Pass = $User.pcred
        $Firstname = $User.firstname
        $Lastname = $User.lastname
        $DisplayName = $Firstname + " " + $Lastname
        $OU = $User.ou
        $Sam = $User.usernm
        $UPN = $User.usernm + "@" + "rtcfingroup.com"
        $Password = $Pass | ConvertTo-SecureString -AsPlainText -Force

        #Check to see if the user already exists in AD
        if (Get-ADUser -F {SamAccountName -eq $Username}) {
            Write-Warning "A user account with username $Username already exists in AD."
        } else {
            New-AdUser -SamAccountName $Username -UserPrincipalName $UPN -Name $DisplayName -GivenName $Firstname -Surname $Lastname -AccountPassword $Password -ChangePasswordAtLogon $False -Enabled $True
            $mtime = Get-Date
            lwrite ("$mtime Username added: $Username")
        }
    }

    # Add username olivia into Domain Admins
    Add-ADGroupMember -Identity "Domain Admins" -Members "olivia"
    Add-ADGroupMember -Identity "Domain Admins" -Members "jason"

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
lwrite ("$mtime End of script")
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
