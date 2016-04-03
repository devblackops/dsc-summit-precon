# 1. Set directory location for demo files
Set-Location -Path C:\Scripts\DSCPreCon\4.Credentails
Remove-Item -Path .\*.mof -Force
invoke-command -computername s2, client {remove-Item c:\cert -Recurse -Force}
Invoke-Command -Computername s2, client {Remove-Item -Path Cert:\LocalMachine\my\* -Recurse -Force}
Break

# So, there is a problem when using credentials
ISE .\1.Config_Credentials.ps1 #Run - and it fails - note error message

# So, let's fix -- the wrong way
ISE .\2.Config_Credentials.ps1
ISE .\s2.mof

# Remeber that domain controller config? Here's the MOF
ISE .\x.Config-DomainController.ps1
ISE .\x.DomainControllerS1.mof.txt

<# ok, so let's do this - first - you will need
A ADCS CA with the certificate enrollment policy web service
and certificate enrollment web service

A workstation (Client) Authentication cert - or any cert that supports
Data Encipherment or Key Encipherment AND Document Encryption enhanced key usage (EKU)

The commands only exist in the ADCSAdministration module on the CA
These will add the cert template for Workstation Authentication

#>

# Invoke-command -ComputerName dc {Get-Catemplate | Select-Object -Property name} 
# Invoke-command -ComputerName dc {Add-caTemplate -Name 'Workstation' -force} 

<#
Note - This will no longer work - recent changes to WMF 5 now require an additional 
Enhanced Key Usage of Document Encryption. 

The error message will contain the following:
Encryption certificates must contain the Data Encipherment or Key Encipherment key usage, and include the 
Document Encryption Enhanced Key Usage (1.3.6.1.4.1.311.80.1).

This means that after adding the template, you will need to perform
the following to add the new requirements.
1. Open MMC
2. Add Certificate Templates - pointed to ADCS
3. Open the properties of the Workstation Authentication certificate
4. Select Extensions tab
5. Edit the Applicaiton Policies and add Document Encyption
6. The rest of this demonstration will now work properly 
#>

# Now, on the TARGET node, get the new certificate
Invoke-Command -computername s2 {Get-Certificate -template 'workstation' -url https://dc.company.pri/ADPolicyProvider_CEP_Kerberos/service.svc/cep -CertStoreLocation Cert:\LocalMachine\My\ -Verbose}

# Create some folders to hold the exported cert
invoke-command -computername s2, client {new-Item c:\cert -ItemType directory -Force}

# Get the cert and export it for encryption of credentials
Invoke-Command -computername s2 {Get-ChildItem -Path cert:\localMachine\my | Where-Object {$_.EnhancedKeyUsageList -like "*Document Encryption*"} |
        Export-Certificate -FilePath c:\Cert\ClientAuth.Cer}

# Copy and install it to the AUTHORING box
copy-item -Path \\s2\c$\cert\* -Destination C:\cert -Recurse -Force
Import-Certificate -FilePath c:\cert\clientauth.cer -CertStoreLocation Cert:\LocalMachine\my

# Now - configure LCM on targets with the Cert Thumbprint
ISE .\4.LCM.ps1
ISE .\s2.meta.mof
Set-DSCLocalConfigurationManager -ComputerName s2 -Path .\ –Verbose 

# And at last - send the config
ISE .\3.Config_Credentials.ps1
Invoke-Command -computername s2 {Get-ChildItem -Path cert:\localMachine\my | Where-Object {$_.EnhancedKeyUsageList -like "*Document Encryption*"} | Select-Object -Property ThumbPrint}
ISE .\s2.mof

# Do Not run UNLESS using the official WMF 5 release 
# http://stackoverflow.com/questions/34006865/dsc-problems-with-credentials-and-build-10586
Start-DscConfiguration -ComputerName s2 -Path .\ -Verbose -Wait
Explorer \\s2\c$

