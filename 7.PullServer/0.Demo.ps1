# 1. Set directory location for demo files
$editor=&{ if (get-command -Name code-insiders.cmd) { 'code-insiders.cmd' } else { 'ISE' }}

Set-Location -Path $PSScriptRoot
Remove-Item -Path .\*.mof -Force
Remove-DnsServerResourceRecord -ComputerName dc.company.pri -ZoneName company.pri -Name DSC -RRType 'A' -Force
Break

# Let's start with some requirements and documentation
<#
1. You will need to install a certificate on the Pull servers - I will show you how
2. Add a DNS Entry for the Pull Server
2. You will need module xPSDesiredStateConfiguration on the Pull server - I will show you how
3. You should look at the documentation inside the module xPSDesiredStateConfiguration - I will...you get the idea
4. You should create YOUR OWN config -- I'll show you mine
5. Then deploy a pull server - AND test it.
#>

# Let's get started by installing a certificate on the Pull server
<#
$ComputerName = '' # Enter you target web server
Invoke-Command -computername $ComputerName {
    Get-Certificate -template 'WebServer' -url 'https://localhost/ADPolicyProvider_CEP_Kerberos/service.svc/cep' `
    -CertStoreLocation Cert:\LocalMachine\My\ -SubjectName 'CN=DSC.Company.Pri, OU=IT, DC=Company, DC=Pri' -Verbose}
    
# Can Export to PFX if needed on other web servers for high availability - Get-Help *pfx*

#>

# DNS for Pull server
Add-DnsServerResourceRecordA -ComputerName dc -name DSC -ZoneName Company.pri -IPv4Address 192.168.3.10

# You need this module - xPSDesiredStateConfiguration on Author box and future Pull server
# My PULL server config also requires xWebAdministration
Find-Module -tag DSCResourceKit
find-Module -name xPSDesired*
Install-Module -name xPSDesiredStateConfiguration, xWebAdministration -force
Invoke-Command -ComputerName dc {Install-Module -name xPSDesiredStateConfiguration, xWebAdministration -force}

# Check out the documentation - specifically
&$editor 'C:\Program Files\WindowsPowerShell\Modules\xPSDesiredStateConfiguration\3.8.0.0\Examples\Sample_xDscWebService.ps1'

# Create HTTPS Pull server configuration with ThumbPrint
&$editor '.\1.Config_Pullserver.ps1'

# Configure LCM if needed -- I like too.
&$editor '.\2.LCM_Settings.ps1'
Set-DscLocalConfigurationManager -ComputerName dc.company.pri -Path .\ -Verbose

# Deploy HTTPS Pull Server
Start-DscConfiguration -ComputerName dc.company.pri -Path .\ -Verbose -Wait

# My config removes components, so you should restart the pull server, or wait and DSC will do it for you
Restart-computer -ComputerName dc.company.pri -wait
Start-DscConfiguration -ComputerName dc.company.pri -UseExisting -Wait -Verbose -Force

# TEst the Pull Server
Start-Process -FilePath iexplore.exe https://dsc.company.pri:8080/PSDSCPullServer.svc
Start-Process -FilePath inetmgr

#################################################################################################################


#############################################################################################


