# 1. Set directory location for demo files
$editor=&{ if (get-command -Name code-insiders.cmd) { 'code-insiders.cmd' } else { 'ISE' }}

Set-Location -Path $PSScriptRoot
Remove-Item -Path .\*.mof -Force
Break

# THIS IS NOT A RUNNING DEMO 

# Let's get started by installing a certificate on the Pull server
# Can Export to PFX if needed on other web servers for high availability - Get-Help *pfx*
$ComputerName = 's1' # Enter you target web servers
Invoke-Command -computername $ComputerName {
    Get-Certificate -template 'WebServer' -url 'https://localhost/ADPolicyProvider_CEP_Kerberos/service.svc/cep' `
    -CertStoreLocation Cert:\LocalMachine\My\ -SubjectName 'CN=DSC.Company.Pri, OU=IT, DC=Company, DC=Pri' -Verbose}
# Then Export to PFX - copy to other server - and Import the PFX    


# You need this module - xPSDesiredStateConfiguration on Author box and ALL future Pull server
Find-Module -tag DSCResourceKit
find-Module -name xPSDesired*
Install-Module -name xPSDesiredStateConfiguration -force
Invoke-Command -ComputerName $ComuterName {Install-Module -name xPSDesiredStateConfiguration -force}

# Create HTTPS Pull server configuration with ThumbPrint
&$editor '.\1.Config_Pullserver_HA.ps1'

# Configure LCM if needed -- I like too.
&$editor '.\2.LCM_Settings.ps1'
Set-DscLocalConfigurationManager -ComputerName s1,s2 -Path .\ -Verbose

# Deploy HTTPS Pull Server
Start-DscConfiguration -ComputerName s1,s2 -Path .\ -Verbose -Wait

############# WAIT -- the following is only if useing NLB - Which is perfect for Pull Servers - And Free ######
############# Other options include a physical load balancer such a Big IP F5 -- way over kill  ###############
############# And of course - a great free load balancer - ARR         ########################################

# Install NLB feature for S1 and S2 - this can be all configured through DSC as well
Invoke-Command -ComputerName s1,s2 {Install-WindowsFeature NLB}

# Install cmdlets for NLB on the author box
Install-WindowsFeature RSAT-NLB

#Create new cluster and add nodes
# Get interface name
Get-NetAdapter -CimSession s1,s2 | Select-Object -Property Name, PSComputername
Get-NlbClusterNodeNetworkInterface -HostName s1
# Create NLB 
New-NlbCluster -HostName s1 -InterfaceName Ethernet0 -ClusterName DSC -ClusterPrimaryIP 192.168.3.200 -SubnetMask 255.255.255.0 -OperationMode Multicast 
Get-NlbCluster -HostName s1 | Add-NlbClusterNode -NewNodeName s2 -NewNodeInterface Ethernet0

# Add DNS record using the Cluster IP address
Add-DnsServerResourceRecordA  -ZoneName company.pri -ComputerName DC -name DSC -IPv4Address 192.168.3.200 

#################################################################################################################





