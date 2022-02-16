# Start of script

# Create a logfile and the function to write the logfile
$logfile = "C:\Terraform\user_data.log"

Function lwrite {
    Param ([string]$logstring)
    Add-Content $logfile -value $logstring
}

$mtime = Get-Date
lwrite("$mtime Starting blue tools script")

$mtime = Get-Date
lwrite("$mtime Setting DNS resolver to public DNS")
$myindex = Get-Netadapter -Name "Ethernet" | Select-Object -ExpandProperty IfIndex
Set-DNSClientServerAddress -InterfaceIndex $myindex -ServerAddresses "8.8.8.8"

lwrite("$mtime Downloading velociraptor client")
# Download velociraptor client windows MSI 
(New-Object System.Net.WebClient).DownloadFile('https://github.com/iknowjason/BlueTools/blob/main/velociraptor-v0.5.6-windows-amd64.msi.zip?raw=true', 'C:\terraform\velociraptor-windows-msi.zip')

# Expand the Velociraptor zip archive
$mtime = Get-Date
lwrite("$mtime Expanding the velociraptor zip file")
Expand-Archive -LiteralPath 'C:\terraform\velociraptor-windows-msi.zip' -DestinationPath 'C:\terraform\velociraptor-windows-msi'

# Install the velociraptor MSI with quiet mode 
$mtime = Get-Date
lwrite("$mtime Install velociraptor with quiet mode")
msiexec.exe /I C:\terraform\velociraptor-windows-msi\velociraptor-v0.5.6-windows-amd64.msi /quiet

# Download Sysmon for HELK
$mtime = Get-Date
lwrite("$mtime Download Sysmon for HELK")
(New-Object System.Net.WebClient).DownloadFile('https://github.com/iknowjason/BlueTools/blob/main/Sysmon.zip?raw=true', 'C:\terraform\Sysmon.zip')

# Download winlogbeat for HELK
$mtime = Get-Date
lwrite("$mtime Download Winlogbeat for HELK")
(New-Object System.Net.WebClient).DownloadFile('https://github.com/iknowjason/BlueTools/blob/main/winlogbeat-7.9.2-windows-x86_64.zip?raw=true', 'C:\terraform\winlogbeat.zip')

# Download configuration zip file, which contains SwiftOnSecurity sysmon config and winlogbeat config
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

# Expand the winlogbeat zip archive
$mtime = Get-Date
lwrite("$mtime Expand the winlogbeat zip archive")
Expand-Archive -LiteralPath 'C:\terraform\winlogbeat.zip' -DestinationPath 'C:\terraform\Winlogbeat'

# Copy the Winlogbeat HELK configuration to destination Winlogbeat folder
$mtime = Get-Date
lwrite("$mtime Copy the Winlogbeat HELK configuration to destination Winlogbeat folder")
Copy-Item "C:\terraform\configs\configs-pc\winlogbeat.yml" -Destination "C:\terraform\Winlogbeat\winlogbeat-7.9.2-windows-x86_64"

# Copy the Winlogbeat folder to C:\ProgramData
$mtime = Get-Date
lwrite("$mtime Copy the Winlogbeat folder to C:\ProgramData")
Copy-Item "C:\terraform\Winlogbeat\winlogbeat-7.9.2-windows-x86_64" -Destination "C:\ProgramData\Winlogbeat" -Recurse

# Install the Winlogbeat service using included powershell script 
$mtime = Get-Date
lwrite("$mtime Install the Winlogbeat service using included powershell script")
C:\ProgramData\Winlogbeat\install-service-winlogbeat.ps1

# Start the Winlogbeat service
$mtime = Get-Date
lwrite("$mtime Start the Winlogbeat service")
start-service winlogbeat

Write-Host "Download Elastic and Atomic Red Team (ART)"
$mtime = Get-Date
lwrite("$mtime Download Elastic and Atomic Red Team (ART)")

(New-Object System.Net.WebClient).DownloadFile('https://github.com/elastic/detection-rules/archive/main.zip', 'C:\terraform\Elastic_Detections.zip')

(New-Object System.Net.WebClient).DownloadFile('https://github.com/redcanaryco/atomic-red-team/archive/refs/heads/master.zip', 'C:\terraform\ART.zip')

(New-Object System.Net.WebClient).DownloadFile('https://github.com/NextronSystems/APTSimulator/releases/download/v0.8.0/APTSimulator_pw_apt.zip', 'C:\terraform\APTSimulator.zip')

Write-Host "Expand Elastic and ART Repos"
$mtime = Get-Date
lwrite("$mtime Expand Elastic and ART Repos")

Expand-Archive -LiteralPath 'C:\terraform\Elastic_Detections.zip' -DestinationPath 'C:\terraform\Elastic_Detections'
Expand-Archive -LiteralPath 'C:\terraform\ART.zip' -DestinationPath 'C:\terraform\ART'

Write-Host "Download and install Python 3.8.6"

### Download Python 3.8
(New-Object System.Net.WebClient).DownloadFile('https://www.python.org/ftp/python/3.8.6/python-3.8.6-amd64.exe
', 'C:\terraform\python-3.8.6-amd64.exe')

### Quiet install of Python
C:\terraform\python-3.8.6-amd64.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0

### Add Path environment variable
$pythonRootFolder = "C:\Users\RTCAdmin\AppData\Local\Programs\Python\Python38"
$pythonScriptsFolder = "C:\Users\RTCAdmin\AppData\Local\Programs\Python\Python38\Scripts"
$path = [System.Environment]::GetEnvironmentVariable('path', 'user')
$path += ";$pythonRootFolder"
$path += ";$pythonScriptsFolder;"
[System.Environment]::SetEnvironmentVariable('path', $path, 'user')

Write-Host "pip install requirements for Elastic"
#### Requirements installation
pip install -r C:\terraform\Elastic_Detections\detection-rules-main\requirements.txt

Write-Host "Install NuGet for ART"
Set-Location -Path "C:\"
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

$script_contents = '

if (Get-Module -Name "Invoke-AtomicRedTeam") {
  Write-Host "Invoke-AtomicRedTeam already installed"
} 
else {
  Write-Host "Invoke-AtomicRedTeam not installed"
  IEX (New-Object Net.WebClient).DownloadString("https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1")
  Install-AtomicRedTeam -Force
}
'

Write-Host "Create Powershell profile to import invoke-atomicredteam with each powershell session"
Set-Content -Path C:\Users\RTCAdmin\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1 -Value $script_contents 

## Now run each attack if you want, looks like you want to invoke from C: directory
# PS C:\>Invoke-AtomicTest T1003 -PathToAtomicsFolder 'C:\terraform\ART\atomic-red-team-master\atomics'

$mtime = Get-Date
$check = Select-String -Path C:\Terraform\user_data.log -Pattern "Join Domain is set to true"
if ($check -ne $null) {
  lwrite("$mtime Domain Join is true ~ Setting DNS resolver back to AD DC")
  $myindex = Get-Netadapter -Name "Ethernet" | Select-Object -ExpandProperty IfIndex
  Set-DNSClientServerAddress -InterfaceIndex $myindex -ServerAddresses "10.100.1.4"
} else {
  lwrite("$mtime Domain Join is false ~ Keeping DNS resolver settings")
}

$mtime = Get-Date
lwrite("$mtime Ending blue tools script")
