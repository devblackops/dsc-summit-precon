# 1. Set directory location for demo files
$editor=&{ if (get-command -Name code-insiders.cmd) { 'code-insiders.cmd' } else { 'ISE' }}

Set-Location -Path $PSScriptRoot
Remove-Item -Path .\*.mof -Force
Remove-Item -Path .\*.checksum -Force
Remove-Item -Path .\SMTP -Recurse -Force
Remove-Item -Path .\*.txt -Recurse -Force
Invoke-Command -ComputerName dc {remove-Item -Path "c:\Program Files\WindowsPowerShell\DscService\Configuration\*" -Recurse -Force}
Invoke-Command -ComputerName dc {remove-Item -Path "c:\Program Files\WindowsPowerShell\DscService\RegistrationKeys.txt" -Recurse -Force}
Break

#Let's take a look at the LCM GUID configuration
&$editor '.\1.LCM_GUID.ps1'
&$editor '.\s1.meta.mof'

# Send to computers LCM
Set-DSCLocalConfigurationManager -ComputerName s1 -Path .\ –Verbose
Get-DscLocalConfigurationManager -CimSession s1
Get-DscLocalConfigurationManager -CimSession s1 | Select-Object -ExpandProperty ConfigurationDownloadManagers

# Here is a quick config for installing SMTP
&$editor '.\2.Config_SNMP.ps1'
&$editor '.\S1.mof'

# Now, we much put the files on teh Pull server
# But we need to name them with a special name - the GUID

# Get the guid, is already assigned
$guid=Get-DscLocalConfigurationManager -CimSession s1 | Select-Object -ExpandProperty ConfigurationID

# Rename MOf with Guid
Rename-Item -Path .\S1.mof -NewName ".\$Guid.mof" -Force 

#Then on Pull server make checksum
New-DSCChecksum -Path ".\$guid.mof" -Force

# Here's what we got
Explorer .\
&$editor ".\$guid.mof.checksum"
Get-MYFileHash -Path ".\$Guid.mof.Checksum" | Format-Table -Property Algorithm, Hash

# Now, Copy Config and Checksum to Pull Servers
$Servers='dc'
$servers | ForEach-Object {Copy-Item -Path ".\$Guid.*" -Destination "\\$_\C$\Program Files\WindowsPowerShell\DscService\Configuration" -Force}
Explorer '\\dc\C$\Program Files\WindowsPowerShell\DscService\Configuration'

# WE can wait - or force the target to get the config
Update-DscConfiguration -ComputerName s1 -Verbose -Wait
Test-DscConfiguration -ComputerName s1
Get-WindowsFeature -ComputerName s1 -name *SMTP*

##########################################
# Another Way -- Using Configuration Names

# First, lets make another config, checksum and save on Pull server
&$editor '.\2.Config_SNMP.ps1'

# Rename MOf To a Role
Rename-Item -Path .\S1.mof -NewName ".\RoleSNMP.mof" -Force 

#Then on Pull server make checksum
New-DSCChecksum -Path ".\RoleSNMP.mof" -Force


# Now, Copy Config and Checksum to Pull Servers
$Servers='dc'
$servers | ForEach-Object {Copy-Item -Path ".\Role*.*" -Destination "\\$_\C$\Program Files\WindowsPowerShell\DscService\Configuration" -Force}
Explorer '\\dc\C$\Program Files\WindowsPowerShell\DscService\Configuration'

# But wait -- there are a couple of things we need to do - Registration Key
# You must create a shared secret on the Pull Server, and use this
# In the LCM config
################################################################################
# The shared secret can be anything - GUID preffered 
Add-Content -Path .\RegistrationKeys.txt -Value '1234567'  # [guid]::NewGuid()
Copy-item -path .\RegistrationKeys.txt -Destination "\\dc\c$\Program Files\WindowsPowerShell\DscService"
Explorer "\\dc\c$\Program Files\WindowsPowerShell\DscService"

# Config the LCM
&$editor '.\3.LCM_ConfigName.ps1'
Set-DscLocalConfigurationManager -path .\ -ComputerName s2 -Verbose 

# WE can wait - or force the target to get the config
Update-DscConfiguration -ComputerName s2 -Verbose -Wait
Test-DscConfiguration -ComputerName s2
Get-WindowsFeature -ComputerName s2 -name *SMTP*
#>
## !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
## Jason, are you going to tell them the truth?
## Are you going to tell them the secret you have been hiding?
## I think you should





#####################################################
#Some Troubleshooting docs for fun

# Checking events
Get-WinEvent -ProviderName Microsoft-Windows-DSC -ComputerName s1
Get-WinEvent -ProviderName Microsoft-Windows-DSC -computername s1 -MaxEvents 5 | Format-Table -Property TimeCreated, Message -AutoSize -Wrap
Get-WinEvent -ProviderName Microsoft-Windows-PowerShell-DesiredStateConfiguration-FileDownloadManager -ComputerName dc
Get-WinEvent -ProviderName Microsoft-Windows-Powershell-DesiredStateConfiguration-PullServer -ComputerName dc


#
Install-Module -name XDSCDiagnostics -Force
#Get-xDSCOperation
#Trace-xDSCOperation -SequenceID
#Update-xDSCEventLogStatus -Channel Analtic -Status Enable
#Update-xDSCEventLogStatus -Channel debug -Status Enable


#################################################################################################################





