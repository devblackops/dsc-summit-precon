[DSCLocalConfigurationManager()]
Configuration LCM_ConfigName 
{
    param
        (
            [Parameter(Mandatory=$true)]
            [string[]]$ComputerName,

            #[Parameter(Mandatory=$true)]
            #[string]$guid, <------------------------Dont need this anymore

            [Parameter(Mandatory=$true)]
            [string]$ThumbPrint

        )      	
	Node $ComputerName {
	
		Settings {
		
			AllowModuleOverwrite = $True
            ConfigurationMode = 'ApplyAndAutoCorrect'
			RefreshMode = 'Pull'
			ConfigurationID = "" # Setting to blank - but can leave a guid in - won't matter
            }

            ConfigurationRepositoryWeb DSCHTTPS {
                ServerURL = 'https://DSC.company.pri:8080/PSDSCPullServer.svc'
                CertificateID = $Thumbprint
                AllowUnsecureConnection = $False
                RegistrationKey = "1234567" # <----------- We Need this 
                ConfigurationNames = @("RoleSNMP") # <----------- We Need this - only one role!
            }
	}
}

$Thumbprint=Invoke-Command -Computername dc {Get-Childitem Cert:\LocalMachine\My | Where-Object {$_.FriendlyName -like "*wild*"} | Select-Object -ExpandProperty ThumbPrint}

# Create the Computer.Meta.Mof in folder
LCM_ConfigName -ComputerName s2 -Thumbprint $Thumbprint -OutputPath .\
