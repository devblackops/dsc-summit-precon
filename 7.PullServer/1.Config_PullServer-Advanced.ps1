$ConfigData=@{
    # Node specific data
    AllNodes = @(

       # All Servers need following identical information 
       @{
            NodeName           = '*'
           # PSDscAllowPlainTextPassword = $true;
           # PSDscAllowDomainUser = $true
            
       },

       # Unique Data for each Role
       @{
            NodeName = 'DC.company.pri'
            Role = @('Web', 'PullServer')
           
            PullServerEndPointName = 'PSDSCPullServer'
            PullserverPort = 8080                      #< - ask me why I use this port
            PullserverPhysicalPath = "$env:SystemDrive\inetpub\wwwroot\PSDSCPullServer"
            PullserverModulePath = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"
            PullServerConfigurationPath = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"
            PullServerThumbPrint = Invoke-Command -Computername 'dc.company.pri' {Get-Childitem Cert:\LocalMachine\My | Where-Object {$_.FriendlyName -like "*wild*"} | Select-Object -ExpandProperty ThumbPrint}

            ComplianceServerEndPointName = 'PSDSCComplianceServer'
            ComplianceServerPort = 9080
            ComplianceServerPhysicalPath = "$env:SystemDrive\inetpub\wwwroot\PSDSCComplianceServer"
            ComplianceServerThumbPrint = 'AllowUnencryptedTraffic'
        }


    );
} 


Configuration WebNodes
{
    # Import the module that defines custom resources
    Import-DscResource -Module PSDesiredStateConfiguration, xPSDesiredStateConfiguration, xWebAdministration

    # Dynamically find the applicable nodes from configuration data
    Node $AllNodes.where{$_.Role -eq 'Web'}.NodeName {
    

#       # Install the IIS role

        WindowsFeature IIS {
        
            Ensure = "Present"
            Name = "Web-Server"
        }

#       # Make sure the following defaults cannot be removed:        

        WindowsFeature DefaultDoc {
        
            Ensure = "Present"
            Name = "Web-Default-Doc"
            DependsOn = '[WindowsFeature]IIS'
        }

        WindowsFeature HTTPErrors {
        
            Ensure = "Present"
            Name = "Web-HTTP-Errors"
            DependsOn = '[WindowsFeature]IIS'
        }

        WindowsFeature HTTPLogging {
        
            Ensure = "Present"
            Name = "Web-HTTP-Logging"
            DependsOn = '[WindowsFeature]IIS'
        }

        WindowsFeature StaticContent {
        
            Ensure = "Present"
            Name = "Web-Static-Content"
            DependsOn = '[WindowsFeature]IIS'
        }

        WindowsFeature RequestFiltering {
        
            Ensure = "Present"
            Name = "Web-Filtering"
            DependsOn = '[WindowsFeature]IIS'
        }
        
 #      # Install additional IIS components to support the Web Application 

        WindowsFeature NetExtens4 {
        
            Ensure = "Present"
            Name = "Web-Net-Ext45"
            DependsOn = '[WindowsFeature]IIS'
        }

        WindowsFeature AspNet45 {
        
            Ensure = "Present"
            Name = "Web-Asp-Net45"
            DependsOn = '[WindowsFeature]IIS'
        }

        WindowsFeature ISAPIExt {
        
            Ensure = "Present"
            Name = "Web-ISAPI-Ext"
            DependsOn = '[WindowsFeature]IIS'
        }

        WindowsFeature ISAPIFilter {

            Ensure = "Present"
            Name = "Web-ISAPI-filter"
            DependsOn = '[WindowsFeature]IIS'
        }
 
 #      # I don't want these defaults for Web-Server to ever be enabled:
 
        WindowsFeature DirectoryBrowsing {
        
            Ensure = "Absent"
            Name = "Web-Dir-Browsing"
            DependsOn = '[WindowsFeature]IIS'
        }
     

        WindowsFeature StaticCompression {
        
            Ensure = "Absent"
            Name = "Web-Stat-Compression"
            DependsOn = '[WindowsFeature]IIS'
        }        

#      # I don't want these Additional settings for Web-Server to ever be enabled:
        # This list is shortened for demo purposes. I include eveything that should not be installed

       WindowsFeature ASP {
        
            Ensure = "Absent"
            Name = "Web-ASP"
            DependsOn = '[WindowsFeature]IIS'
        }

       WindowsFeature CGI {
        
            Ensure = "Absent"
            Name = "Web-CGI"
            DependsOn = '[WindowsFeature]IIS'
        }

       WindowsFeature IPDomainRestrictions {
        
            Ensure = "Absent"
            Name = "Web-IP-Security"
            DependsOn = '[WindowsFeature]IIS'
        }

# !!!!! # GUI Remote Management of IIS requires the following: - people always forget this until too late

        WindowsFeature Management {

            Name = 'Web-Mgmt-Service'
            Ensure = 'Present'
        }

        Registry RemoteManagement { # Can set other custom settings inside this reg key

            Key = 'HKLM:\SOFTWARE\Microsoft\WebManagement\Server'
            ValueName = 'EnableRemoteManagement'
            ValueType = 'Dword'
            ValueData = '1'
            DependsOn = @('[WindowsFeature]IIS','[WindowsFeature]Management')
       }

       Service StartWMSVC {

            Name = 'WMSVC'
            StartupType = 'Automatic'
            State = 'Running'
            DependsOn = '[Registry]RemoteManagement'

       }
 
#       # Often, It's common to disable the default website and then create your own
        # - dont do this to Pull Servers, ADCS or other Services that use the default website

        xWebsite DefaultSite {

            Name            = "Default Web Site"
            State           = "Started"
            PhysicalPath    = "C:\inetpub\wwwroot"
            DependsOn       = "[WindowsFeature]IIS"
        }


    } #End Node Role Web

###############################################################################

    Node $AllNodes.where{$_.Role -eq 'PullServer'}.NodeName {

#       # This installs both, WebServer and the DSC Service for a pull server
#       # You could do everything manually - which I prefer

         WindowsFeature DSCServiceFeature {

            Ensure = "Present"
            Name   = "DSC-Service"
        }

       xDscWebService PSDSCPullServer {
        
            Ensure = "Present"
            EndpointName = $Node.PullServerEndPointName
            Port = $Node.PullServerPort   # <--------------------------------------- Why this port?
            PhysicalPath = $Node.PullserverPhysicalPath
            CertificateThumbPrint =  $Node.PullServerThumbprint # <------------------------- Certificate Thumbprint
            ModulePath = $Node.PullServerModulePath
            ConfigurationPath = $Node.PullserverConfigurationPath
            State = "Started"
            DependsOn = "[WindowsFeature]DSCServiceFeature"
        }

        xDscWebService PSDSCComplianceServer {
        
            Ensure = "Present"
            EndpointName = $Node.ComplianceServerEndPointName
            Port = $Node.ComplianceServerPort
            PhysicalPath = $Node.ComplianceServerPhysicalPath
            CertificateThumbPrint =  $Node.ComplianceServerThumbPrint
            State = "Started"
            # IsComplianceServer = $true - property removed in version 3.8.0.0 -- dont know why
            DependsOn = ("[WindowsFeature]DSCServiceFeature","[xDSCWebService]PSDSCPullServer")
        }

 
       
    } # End Node PullServer

} # End Config

#break
WebNodes -ConfigurationData $ConfigData -OutputPath .\

