$ConfigData=@{
    # Node specific data
    AllNodes = @(

       # All Servers need following identical information 
       @{
            NodeName           = '*'
            PSDscAllowPlainTextPassword = $true;
            PSDscAllowDomainUser = $true
            
       },

       # Unique Data for each Role
       @{
            NodeName = 's1.company.pri'
            Role = @('Web', 'OpenSite')
           
            SourcePath = '\\client\WebSiteForDemo' # Content Source Location
            DestinationPath = 'C:\WebSite' # Content Destination Location
            WebAppPoolName = 'MyWebPool' # Name of the Application Pool to create
            WebSiteName = 'MyWeb' # Name of the website to create - this will also be hostname for DNS
            DomainName = 'Company.Pri' # Remaining Domain name for Host Header i.e. Company.com and DNS
            DNSIPAddress = '192.168.3.51' # IP Address for DNS of the Website
        }

         @{
            NodeName = 's2.company.pri'
            Role = @('Web', 'SecuredSite','Application')
           
            SourcePath = '' # Content Source Location - not used for this app
            DestinationPath = 'C:\Windows\web\PowerShellWebAccess\wwwroot' # Empty Content Destination - to be filled with app install         
            WebAppPoolName = 'PSWAPool' # Name of the Application Pool to create
            WebSiteName = 'PSWA' # Name of the website to create - this will also be hostname for DNS           
            DomainName = 'Company.Pri' # Remaining Domain name for Host Header i.e. Company.com and DNS            
            DNSIPAddress = '192.168.3.52' # IP Address for DNS of the Website
            ThumbPrint = Invoke-Command -Computername 's2.company.pri' {Get-Childitem Cert:\LocalMachine\My | Where-Object {$_.FriendlyName -like "*wild*"} | Select-Object -ExpandProperty ThumbPrint}
            
        }

    );
} 


Configuration WebNodes
{
    # Import the module that defines custom resources
    Import-DscResource -Module PSDesiredStateConfiguration, xWebAdministration, xDNSserver, cNTFSPermission, PSWAAuthorization

    # Dynamically find the applicable nodes from configuration data
    Node $AllNodes.where{$_.Role -eq 'Web'}.NodeName {
    

#       # Install the IIS role
        WindowsFeature IIS {
        
            Ensure          = "Present"
            Name            = "Web-Server"
        }

#       # Make sure the following defaults cannot be removed:        

        WindowsFeature DefaultDoc {
        
            Ensure          = "Present"
            Name            = "Web-Default-Doc"
            DependsOn       = '[WindowsFeature]IIS'
        }

        WindowsFeature HTTPErrors {
        
            Ensure          = "Present"
            Name            = "Web-HTTP-Errors"
            DependsOn       = '[WindowsFeature]IIS'
        }

        WindowsFeature HTTPLogging {
        
            Ensure          = "Present"
            Name            = "Web-HTTP-Logging"
            DependsOn       = '[WindowsFeature]IIS'
        }

        WindowsFeature StaticContent {
        
            Ensure          = "Present"
            Name            = "Web-Static-Content"
            DependsOn       = '[WindowsFeature]IIS'
        }

        WindowsFeature RequestFiltering {
        
            Ensure          = "Present"
            Name            = "Web-Filtering"
            DependsOn       = '[WindowsFeature]IIS'
        }
        
 #      # I don't want these defaults for Web-Server to ever be enabled:
 
        WindowsFeature DirectoryBrowsing {
        
            Ensure          = "Absent"
            Name            = "Web-Dir-Browsing"
            DependsOn       = '[WindowsFeature]IIS'
        }
     

        WindowsFeature StaticCompression {
        
            Ensure          = "Absent"
            Name            = "Web-Stat-Compression"
            DependsOn       = '[WindowsFeature]IIS'
        }        

 #      # Install additional IIS components to support the Web Application 

        WindowsFeature NetExtens4 {
        
            Ensure          = "Present"
            Name            = "Web-Net-Ext45"
            DependsOn       = '[WindowsFeature]IIS'
        }

        WindowsFeature AspNet45 {
        
            Ensure          = "Present"
            Name            = "Web-Asp-Net45"
            DependsOn       = '[WindowsFeature]IIS'
        }

        WindowsFeature ISAPIExt {
        
            Ensure          = "Present"
            Name            = "Web-ISAPI-Ext"
            DependsOn       = '[WindowsFeature]IIS'
        }

        WindowsFeature ISAPIFilter {

            Ensure          = "Present"
            Name            = "Web-ISAPI-filter"
            DependsOn       = '[WindowsFeature]IIS'
        }

#       # Disable the Default Web Site

        xWebsite DefaultSite {

            Name            = "Default Web Site"
            State           = "Stopped"
            PhysicalPath    = "C:\inetpub\wwwroot"
            DependsOn       = "[WindowsFeature]IIS"
        }

#       # GUI Remote Management of IIS requires the following:

        WindowsFeature Management {

            Name = 'Web-Mgmt-Service'
            Ensure = 'Present'
        }

        Registry RemoteManagement {
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

    } #End Node Role Web

###############################################################################

    Node $AllNodes.where{$_.Role -eq 'OpenSite'}.NodeName {

        File WebContent {
        
            Ensure = 'Present'
            SourcePath = $Node.SourcePath
            DestinationPath = $Node.DestinationPath
            Recurse = $true
            Type = 'Directory'
            DependsOn = '[WindowsFeature]AspNet45'
        }  
        
 #      # Config application pool
        xWebAppPool WebAppPool { 
        
            Ensure = "Present"
            Name = $Node.WebAppPoolName
            autoStart = "true"  
            managedRuntimeVersion = "v4.0"
            managedPipelineMode = "Integrated"
            startMode = "AlwaysRunning"
            identityType = "ApplicationPoolIdentity"
            restartSchedule = @("18:30:00","05:00:00")
            DependsOn = @('[WindowsFeature]IIS','[WindowsFeature]AspNet45') 
 
        }
 
       # Configure web site
       xWebsite WebSite
       {
           Ensure = "Present"
           Name = $Node.WebSiteName
           State = "Started"
           PhysicalPath = $Node.DestinationPath
           ApplicationPool = $Node.WebAppPoolName
           BindingInfo = MSFT_xWebBindingInformation { 
                             
                              Protocol = "HTTP" 
                              Port = 80
                              Hostname = "$($Node.WebSiteName).$($Node.DomainName)"
                            } 
           DependsOn       = '[xWebAppPool]WebAppPool'
          
       }
       
    } # End Node OpenSite

    ###############################################################################

    Node $AllNodes.where{$_.Role -eq 'SecuredSite'}.NodeName {

        
        # Create an empty directory for the application install
        File WebContent {
        
            Ensure = 'Present'
            #SourcePath = $Node.SourcePath
            DestinationPath = $Node.DestinationPath
            #Recurse = $true
            Type = 'Directory'
            DependsOn = '[WindowsFeature]AspNet45'
        }

#      # Config application pool
        xWebAppPool WebAppPool { 
        
            Ensure = "Present"
            Name = $Node.WebAppPoolName
            autoStart = "true"  
            managedRuntimeVersion = "v4.0"
            managedPipelineMode = "Integrated"
            startMode = "AlwaysRunning"
            identityType = "ApplicationPoolIdentity"
            restartSchedule = @("18:30:00","05:00:00")
            DependsOn = @('[WindowsFeature]IIS','[WindowsFeature]AspNet45') 
 
        }

        xWebsite SecuredSite
        {
            Ensure          = "Present"
            Name            = $Node.WebSiteName
            State           = "Started"
            PhysicalPath    = $Node.DestinationPath
            ApplicationPool = $Node.WebAppPoolName
            BindingInfo     =  MSFT_xWebBindingInformation {  
                             
                               Protocol              = "HTTPS" 
                               Port                  = 443 
                               Hostname              = "$($Node.WebSiteName).$($Node.DomainName)"
                               CertificateThumbprint = $Node.ThumbPrint
                               CertificateStoreName  = "MY" 
                             } 
            DependsOn       = @('[xWebAppPool]WebAppPool', '[File]WebContent')

        }

          
    } #End Node SecuredSite
    ####################################################

    Node $AllNodes.where{$_.Role -eq 'Application'}.NodeName {

#       # Installing the Application
        WindowsFeature PSWA {
        
            Ensure          = "Present"
            Name            = "WindowsPowerShellWebAccess"
            DependsOn       = @('[WindowsFeature]IIS','[WindowsFeature]AspNet45')
        }

#       # Setting permissions for the application
        cNTFSPermission AppPoolPermission {
        
            Ensure          = "Present"
            Account         = "users"
            Access          = "Allow"
            Path            = "C:\Windows\web\PowerShellWebAccess\data\AuthorizationRules.xml"
            Rights          = 'ReadAndExecute'
            NoInherit       = $true
            DependsOn       = '[xWebAppPool]WebAppPool'
        } 

 #      # Setting permissions for the Application  
        PSWAAuthorization Rule1 
        {

            Ensure          = 'Present'
            RuleName        = 'Rule1'
            Domain          = 'Company'
            Group           = 'Company\Domain Admins'
            ComputerName    = 's1.company.pri'
            Configuration   = '*' 
            DependsOn       = @('[xWebsite]SecuredSite','[WindowsFeature]PSWA')  

        }

    } # End of Node
} # End Config

#break
WebNodes -ConfigurationData $ConfigData -OutputPath .\

