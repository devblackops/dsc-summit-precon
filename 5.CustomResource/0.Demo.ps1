# 1. Set directory location for demo files
$editor=&{ if (get-command -Name code-insiders.cmd) { 'code-insiders.cmd' } else { 'ISE' }}

Set-Location -Path $PSScriptRoot
Remove-Item -path 'C:\Program Files\WindowsPowerShell\Modules\ControlService' -Recurse -Force
Remove-Item .\controlservice -Recurse -Force
Remove-Item -Path .\*.mof -Force
Remove-DscConfigurationDocument -CimSession Client -Stage current
Break

# First - there is a snippet
&$editor '.\Snippet.ps1'

# Now, for a simple class
&$editor '.\ControlService.ps1'

# You should also make an about_ help file
&$editor '.\About_ControlService.help.txt'

# To package the class, you need to put it in a folder
New-Item .\ControlService -ItemType Directory
New-Item .\ControlService\en-us -ItemType Directory

# Make it a module and copy to directory! - dont forget the help file!
Copy-Item -Path .\ControlService.ps1 -Destination .\ControlService\ControlService.psm1
Copy-Item -Path .\About_ControlService.help.txt -Destination .\ControlService\en-us

# Create a Manifest
New-ModuleManifest -Path .\ControlService\Controlservice.psd1 -RootModule Controlservice.psm1 `
    -Guid ([GUID]::NewGuid()) -ModuleVersion 1.0 -Author Jason `
    -Description 'My Test Service Class' -DscResourcesToExport 'ControlService' 

# Wanna see the manifest?
&$editor '.\ControlService\Controlservice.psd1'
Explorer .\ControlService

# Now, write a config - but wait -- RED SQIGGLY LINES!
&$editor '.\Config_Service.ps1'

#Copy new resource to authoring computer -- and target if not using pull Server
New-Item -path 'C:\Program Files\WindowsPowerShell\Modules\ControlService' -ItemType directory -Force
Copy-Item -Path .\ControlService\* -Destination 'C:\Program Files\WindowsPowerShell\Modules\Controlservice' -Force -Recurse
explorer 'C:\Program Files\WindowsPowerShell\Modules'

# Check to see if authoring can see the resource
Get-DscResource
Get-Help About_Controlservice

# Open config again and run
&$editor '.\Config_Service.ps1' # AND RUN IT!

# Let's try!
Invoke-Command -ComputerName Client {Stop-service -name bits}
Invoke-Command -ComputerName Client {Get-service -name bits}
Start-DscConfiguration -ComputerName Client -Path .\ -Verbose -Wait

# This is the Get function
Get-DscConfiguration -CimSession Client
Get-service -name bits

##########################################################################33

