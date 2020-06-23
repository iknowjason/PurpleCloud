$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$DefaultUsername = "lars"
$DefaultPassword = "Password123"
$DefaultDomainName = "RTC.LOCAL"
Set-ItemProperty $Regpath "AutoAdminLogon" -Value "1" -type String
Set-ItemProperty $Regpath "DefaultUsername" -Value "$DefaultUsername" -type String
Set-ItemProperty $Regpath "DefaultPassword" -Value "$DefaultPassword" -type String
Set-ItemProperty $Regpath "DefaultDomainName" -Value "$DefaultDomainName" -type String
Restart-Computer -Force
