# 1. Set directory location for demo files
$editor=&{ if (get-command -Name code-insiders.cmd) { 'code-insiders.cmd' } else { 'ISE' }}

Set-Location -Path $PSScriptRoot
Remove-Item -Path .\*.mof -Force
Break

# Have you written a function before?
&$editor '.\1.Function-Get-Foo.ps1'

# So, let write a DSC config
&$editor '.\1.Config-set-service.ps1'

# Take a look at the MOF files
&$editor '.\S1.mof'

# Apply the MOF configs to the servers
Invoke-command -ComputerName s1,s2 {Stop-Service -name bits}
Start-DscConfiguration -CimSession s1,s2 -Path .\ -Verbose -Wait
Get-Service -ComputerName s1,s2 -name bits

# Let's take a look at the configs
Start-Process -FilePath Explorer '\\s1\C$\Windows\System32\configuration'
Remove-DscConfigurationDocument -CimSession s1,s2 -Stage Current # Current Pending Previos

#############################################################################################
