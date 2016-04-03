# 1. Set directory location for demo files
Set-Location -Path C:\Scripts\DSCPreCon\3.Resources
Remove-Item -Path .\*.mof -Force
Break


# Let's find and use local resources
Get-DscResource
Get-DscResource -Name WindowsProcess | Select-Object -ExpandProperty properties
Get-DscResource -name WindowsProcess -Syntax # Show in ISE

# Here's the configuration using the resource
ISE .\1.Config-Process.ps1
ISE .\Client.mof

# Let's try it on the Client
Start-DscConfiguration -Path .\ -ComputerName Client -Verbose -Wait
Get-DscConfiguration -CimSession Client # Gets current
Test-DscConfiguration -ComputerName client -Detailed | format-List -Property * # Test to see if matches desire


# Let's check for them
Get-Process -name notepad, mspaint

# Let's kill them and force the Client to run the config again
Get-Process -name notepad, mspaint | Stop-Process -Force
Get-Process -name notepad, mspaint
Test-DscConfiguration -ComputerName client -Detailed | format-List -Property *
Start-DscConfiguration -ComputerName Client -Verbose -Wait -UseExisting #Note switch - Client already has config 
Test-DscConfiguration -ComputerName client -Detailed | format-List -Property *

# Let's clean this up and try another
Remove-DscConfigurationDocument -CimSession client -Stage Current
Get-Process -name notepad, mspaint | Stop-Process -Force

# These will now fail becuase there is no config
Start-DscConfiguration -ComputerName Client -Verbose -Wait -UseExisting #Will now fail
Test-DscConfiguration -ComputerName client -Detailed #Will now fail

# Other RESOURCES!!!!!!!  YEA!!!!!!
Find-Module -Tag DSCResourceKit 
Find-Module -name xActiveDirectory

# I need to download this reource and put it in a special place
Explorer 'C:\Program Files\WindowsPowerShell\Modules'
Install-Module -name xActiveDirectory
Explorer 'C:\Program Files\WindowsPowerShell\Modules' # Now its there
Get-DscResource #Show Name and ModuleName
Update-Module -Name xActiveDirectory # Easy to update

# Make a config using the new resource
Get-DscResource -Name xADDomainController | Select-Object -ExpandProperty properties

ISE .\2.Config-DomainController.ps1

# Test it! And configure a new one - This is going to fail!
Get-ADDomainController -Discover
Get-ADDomainController | Select-Object -Property HostName
Start-DscConfiguration -ComputerName s1 -Path .\ -Verbose -Wait # SEE ERROR MESSAGE
Remove-DscConfigurationDocument -CimSession s1 -Stage pending # Remove pending config

# DO NOT RUN - One Way - 2 options -- This one not the best
copy-item -path 'C:\Program Files\WindowsPowerShell\Modules\xActiveDirectory' -Destination "\\s1\c$\Program Files\WindowsPowerShell\Modules\xActiveDirectory" -recurse -force
Explorer '\\s1\c$\Program Files\WindowsPowerShell\Modules'
Remove-Item -Path "\\s1\c$\Program Files\WindowsPowerShell\Modules\xActiveDirectory" -Recurse -Force
Explorer '\\s1\c$\Program Files\WindowsPowerShell\Modules'

# A Better way!
Invoke-command -ComputerName s1 {Install-module -name xActiveDirectory -Force}

# And try again
Remove-DscConfigurationDocument -CimSession s1 -Stage pending
Start-DscConfiguration -ComputerName s1 -Path .\ -Verbose -Wait 

# After Reboot 
Test-Connection -ComputerName s1 -Quiet -Count 1
ServerManager

##############################################################################################