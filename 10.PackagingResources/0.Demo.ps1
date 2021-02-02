# 1. Set directory location for demo files
$editor=&{ if (get-command -Name code-insiders.cmd) { 'code-insiders.cmd' } else { 'ISE' }}

Set-Location -Path $PSScriptRoot
Remove-Item -Path .\*.mof -Force
Remove-Item -Path .\*.checksum -Force
Remove-Item -Path .\*.zip -Force
Invoke-Command -ComputerName dc {remove-Item -Path "c:\Program Files\WindowsPowerShell\DscService\Configuration\*" -Recurse -Force}
Invoke-Command -ComputerName dc {remove-Item -Path "c:\Program Files\WindowsPowerShell\DscService\Modules\*" -Recurse -Force}
Break

Add-DnsServerResourceRecordA -ComputerName dc -name MyWeb -ZoneName Company.pri -IPv4Address 192.168.3.51
Add-DnsServerResourceRecordA -ComputerName dc -name PSWA -ZoneName Company.pri -IPv4Address 192.168.3.52

# Here is a quick config - this is cool - but notice RED SQIGGLIES!
&$editor '.\1.Config_Web_MultiSite_Allnodes.ps1'

# The author box needs the resources for development
Explorer .\
copy-item -Path .\cNTFSPermission -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Force
copy-item -Path .\xDnsServer -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Force
copy-item -Path .\xWebAdministration -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Force
copy-item -Path .\PSWAAuthorization -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Force

# Now the config should be fine -- Run - dont show much yet - just idea
&$editor '.\1.Config_Web_MultiSite_Allnodes.ps1'

# Rename MOf with Guid
Rename-Item -Path .\s1.company.pri.mof -NewName ".\RoleWeb.mof" -Force 
Rename-Item -Path .\s2.company.pri.mof -NewName ".\RoleSecuredWeb.mof" -Force 

#Then on Pull server make checksum
New-DSCChecksum -Path ".\RoleWeb.mof" -Force
New-DSCChecksum -Path ".\RoleSecuredWeb.mof" -Force

# Now, Copy Config and Checksum to Pull Servers
$Servers='dc'
$servers | ForEach-Object {Copy-Item -Path ".\Role*.*" -Destination "\\$_\C$\Program Files\WindowsPowerShell\DscService\Configuration" -Force}
Explorer '\\dc\C$\Program Files\WindowsPowerShell\DscService\Configuration'

# But now we have a problem - what about the resources???

# Bundle the Resources
# THIS IS IMPORTANT - YOU NEED THE VERSION NUMBER FROM THE MANIFEST!!!
&$editor '.\PSWAAuthorization\PSWAAuthorization.psd1'

# Now -- ZIP IT! name + version - Module_1.0.zip
Compress-Archive -Path .\PSWAAuthorization\* -DestinationPath .\PSWAAuthorization_1.2.0.0.zip -Force
Compress-Archive -Path .\cNTFSPermission\* -DestinationPath .\cNTFSPermission_1.0.zip -force
Compress-Archive -Path .\xDnsServer\1.5.0.0\* -DestinationPath .\xDnsServer_1.5.0.0.zip -Force
Compress-Archive -Path .\xWebAdministration\1.9.0.0\* -DestinationPath .\xWebAdministration_1.9.0.0.zip -Force

# CheckSum it!
New-DSCCheckSum -path .\PSWAAuthorization_1.2.0.0.zip -Force
New-DscChecksum -Path .\cNTFSPermission_1.0.zip -Force
New-DscChecksum -Path .\xDnsServer_1.5.0.0.zip -Force
New-DscChecksum -Path .\xWebAdministration_1.9.0.0.zip -Force

# Copy Config and Resource to Pull Servers
$Servers='DC'
#$servers | ForEach-Object {Copy-Item -Path .\ -Destination "\\$_\C$\Program Files\WindowsPowerShell\DscService\Configuration" -Force}
#Explorer '\\s1\C$\Program Files\WindowsPowerShell\DscService\Configuration'
$servers | ForEach-Object {Copy-Item -Path .\*.zip -Destination "\\$_\C$\Program Files\WindowsPowerShell\DscService\Modules" -Force}
$servers | ForEach-Object {Copy-Item -Path .\*.CheckSum -Destination "\\$_\C$\Program Files\WindowsPowerShell\DscService\Modules" -Force}
Explorer '\\dc\C$\Program Files\WindowsPowerShell\DscService\Modules'

# Well- now we are ready to set the LCM on the Nodes and test!
# But I HAVE A NEW LCM THAT IS BETTER AND EASIER FOR MULTI NODES

&$editor '.\3.New_LCM.ps1'

# Cool way to grab multiple LCM configs and send -- you should make a function out of this
$ComputerName=Get-ChildItem -Path .\*.meta.mof | Select-Object -ExpandProperty Name | ForEach-Object {$_.trim(".meta.mof")}
Set-DscLocalConfigurationManager -ComputerName $computerName -Path .\ -Verbose -Force


# I dont want to wait so lets UPDATE!
Update-DscConfiguration -ComputerName s1,s2 -Verbose -Wait

# Now - lets check what happened to the resources
Explorer '\\s1\c$\Program Files\WindowsPowerShell\Modules'
Explorer '\\s2\c$\Program Files\WindowsPowerShell\Modules'

# Let's test the websites

Start-Process -Filepath iexplore http://MyWeb.company.pri

Start-Process -Filepath iexplore https://pswa.company.pri

# Wanna see the cool config?
&$editor '.\1.Config_Web_MultiSite_Allnodes.ps1'
