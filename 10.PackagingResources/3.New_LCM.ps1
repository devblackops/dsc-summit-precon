$ConfigData=@{
    # Node specific data
    AllNodes = @(

       # All Servers need following identical information 
       @{
           NodeName           = '*'
           AllowModuleOverwrite = $True
           ConfigurationMode = 'ApplyAndAutoCorrect'
           RefreshMode = 'Pull'
           ConfigurationID = '' # only use if working with GUID named configs

           ServerURL = 'https://DSC.company.pri:8080/PSDSCPullServer.svc'
           CertificateID = 1234 #Invoke-Command -Computername dc {Get-Childitem Cert:\LocalMachine\My | Where-Object {$_.FriendlyName -like "*wild*"} | Select-Object -ExpandProperty ThumbPrint}
           AllowUnSecureConnection = $False
           RegistrationKey = '1234567'          
            
       },

       # Unique Data for each Role

       @{
            NodeName = 's1.company.pri'
            ConfigurationNames = 'RoleWeb'
        }

       @{
            NodeName = 's2.company.pri'
            ConfigurationNames = 'RoleSecuredWeb'
        }


    );
} 

[DSCLocalConfigurationManager()]
Configuration LCM
{
    
    # Dynamically find the applicable nodes from configuration data
    Node $AllNodes.NodeName {
 		Settings {
		
			AllowModuleOverwrite = $Node.AllowModuleOverwrite
            ConfigurationMode = $Node.ConfigurationMode
			RefreshMode = $Node.RefreshMode
			ConfigurationID = $Node.ConfigurationID
            }

            ConfigurationRepositoryWeb DSCHTTPS {
                ServerURL = $Node.ServerURL
                CertificateID = $Node.CertificateID
                AllowUnsecureConnection = $Node.AllowUnsecureConnection
                RegistrationKey = $Node.RegistrationKey
                ConfigurationNames = @("$($Node.ConfigurationNames)") 
            }
	}   # End Node

} # End Config

LCM -ConfigurationData $ConfigData -OutputPath .\