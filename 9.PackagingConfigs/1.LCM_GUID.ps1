[DSCLocalConfigurationManager()]
Configuration LCM_GUID 
{
    param
        (
            [Parameter(Mandatory=$true)]
            [string[]]$ComputerName,

            [Parameter(Mandatory=$true)]
            [string]$guid, #<------------------------------

            [Parameter(Mandatory=$true)]
            [string]$ThumbPrint #<-------------------------

        )      	
	Node $ComputerName {
	
		Settings {
		
			AllowModuleOverwrite = $True
            ConfigurationMode = 'ApplyAndAutoCorrect'
			RefreshMode = 'Pull' #<-------------------------
			ConfigurationID = $guid #<----------------------
            }

            ConfigurationRepositoryWeb DSCHTTPS {
                ServerURL = 'https://DSC.company.pri:8080/PSDSCPullServer.svc'
                CertificateID = $Thumbprint #<-------------------------------
                AllowUnsecureConnection = $False #<--------------------------
            }
 	}
}

# Create Guid for the computers
$guid=[guid]::NewGuid()

$Thumbprint=Invoke-Command -Computername 'DC.company.pri' {Get-Childitem Cert:\LocalMachine\My | Where-Object {$_.FriendlyName -like "*wild*"} | Select-Object -ExpandProperty ThumbPrint}

# Create the Computer.Meta.Mof in folder
LCM_GUID -ComputerName s1 -Guid $guid -Thumbprint $Thumbprint -OutputPath .\ 
