# 1. Set directory location for demo files
$editor=&{ if (get-command -Name code-insiders.cmd) { 'code-insiders.cmd' } else { 'ISE' }}

Set-Location -Path $PSScriptRoot
Remove-Item -path 'C:\Program Files\WindowsPowerShell\Modules\CompositeDemo' -Recurse -Force
Remove-Item .\CompositeDemo -Recurse -Force
Remove-Item -Path .\*.mof -Force
Break

# Seperating Configuration data from the config
&$editor '.\1.RegularConfig.ps1'
&$editor '.\2.ConfigDataConfig.ps1'

# Nested configurations
&$editor '.\3.Nested.ps1'

# Composite Resources - Start with a config with no node
&$editor '.\4.Config_Base.ps1'

# Then, create a folder and copy to BaseConfig.schema.PSM1
# Note - This uses the old folder structure for Resources
NEw-Item .\CompositeDemo\DSCResources\BaseConfig -ItemType Directory -Force
Copy-Item .\4.Config_base.ps1 -Destination .\CompositeDemo\DSCResources\baseconfig\BaseConfig.schema.psm1 -force

# Create Manifest for Baseconfig
New-ModuleManifest -Path .\CompositeDemo\DSCResources\baseconfig\baseconfig.psd1 `
    -ModuleVersion 1.0 -RootModule 'BaseConfig.schema.psm1'

# Create the Manifest for the Main module
New-ModuleManifest -Path .\CompositeDemo\CompositeDemo.psd1 `
    -Guid ([GUID]::NewGuid()) -ModuleVersion 1.0 -Author Jason -CompanyName Demo `
    -Description 'nested resource module'


# Copy to modules folder like a resource
Copy-Item -Path .\CompositeDemo -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Force
Explorer 'C:\Program Files\WindowsPowerShell\Modules'
Get-DscResource

# Create a configuration using the composite resource
&$editor '.\5.WebConfig.ps1'


# Partial Configs -- here's the concept
#______________________________________


##########################################################################33

