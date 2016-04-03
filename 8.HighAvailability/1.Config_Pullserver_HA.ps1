$ConfigData=@{
    # Node specific data
    AllNodes = @(

       # All Servers need following identical information 
       @{
            NodeName           = '*' 
       },

       # Unique Data for each Role
         @{
            NodeName = 'S1.company.pri'
            Role = @('HTTPSPullServer')
  
            CertThumbPrint = Invoke-Command -Computername 'S1.company.pri' {Get-Childitem Cert:\LocalMachine\My | Where-Object {$_.FriendlyName -like "*wild*"} | Select-Object -ExpandProperty ThumbPrint}
          
        }

          @{
            NodeName = 'S2.company.pri'
            Role = @('HTTPSPullServer')
  
            CertThumbPrint = Invoke-Command -Computername 'S2.company.pri' {Get-Childitem Cert:\LocalMachine\My | Where-Object {$_.FriendlyName -like "*wild*"} | Select-Object -ExpandProperty ThumbPrint}
          
        }

    );
} 


Configuration HTTPSPull
{
    # Import the module that defines custom resources
    Import-DscResource -Module PSDesiredStateConfiguration, xPSDesiredStateConfiguration

    # Dynamically find the applicable nodes from configuration data
    Node $AllNodes.where{$_.Role -eq 'HTTPSPullServer'}.NodeName {
    
#       # This installs both, WebServer and the DSC Service for a pull server
#       # You could do everything manually - but not needed
         WindowsFeature DSCServiceFeature {

            Ensure = "Present"
            Name   = "DSC-Service"
        }


#       # GUI Remote Management of IIS requires the following:
#       # I always add this to every web server - Absolutly required for Core

        WindowsFeature Management {

            Name = 'Web-Mgmt-Service'
            Ensure = 'Present'
            DependsOn = @('[WindowsFeature]DSCServiceFeature')
        }

        Registry RemoteManagement {
            Key = 'HKLM:\SOFTWARE\Microsoft\WebManagement\Server'
            ValueName = 'EnableRemoteManagement'
            ValueType = 'Dword'
            ValueData = '1'
            DependsOn = @('[WindowsFeature]DSCServiceFeature','[WindowsFeature]Management')
       }

       Service StartWMSVC {
            Name = 'WMSVC'
            StartupType = 'Automatic'
            State = 'Running'
            DependsOn = '[Registry]RemoteManagement'

       }

       xDscWebService PSDSCPullServer {
        
            Ensure = "Present"
            EndpointName = "PSDSCPullServer"
            Port = 8080   # <--------------------------------------- Why this port?
            PhysicalPath = "$env:SystemDrive\inetpub\wwwroot\PSDSCPullServer"
            CertificateThumbPrint =  $Node.CertThumbprint # <---------------------------------- Certificate Thumbprint
            ModulePath = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"
            ConfigurationPath = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"
            State = "Started"
            DependsOn = "[WindowsFeature]DSCServiceFeature"
        }

        xDscWebService PSDSCComplianceServer {
        
            Ensure = "Present"
            EndpointName = "PSDSCComplianceServer"
            Port = 9080
            PhysicalPath = "$env:SystemDrive\inetpub\wwwroot\PSDSCComplianceServer"
            CertificateThumbPrint = "AllowUnencryptedTraffic" #<--------------------------HTTP reporting site
            State = "Started"
            IsComplianceServer = $true
            DependsOn = ("[WindowsFeature]DSCServiceFeature","[xDSCWebService]PSDSCPullServer")
        }


    } #End Node Role Web

} # End Config

HTTPSPull -ConfigurationData $ConfigData -outputPath .\