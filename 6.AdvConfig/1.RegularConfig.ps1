configuration PWA
{
    param
    (
        # Target nodes to apply the configuration
        [Parameter(Mandatory = $true)]
        [string[]]$NodeName,

        # Name of the website to create
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$PSWASiteName,

        # Name of the website to create
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$PSWAppPoolName,

        # Certificate ThumbPrint
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$CertThumbprint

        
    )

    # Import the module that defines custom resources
    Import-DscResource -Module cWebAdministration
    Import-DscResource -module cNTFSPermission
    Import-DscResource -Module cPSWAAuthorization #Mine


    Node $NodeName
    {
        # Install the IIS role
        WindowsFeature IIS
        {
            Ensure          = "Present"
            Name            = "Web-Server"
        }

        # Make sure the defaults exist - unneeded defaults for PSWA are:
        # Directory Browsing, HTTP Logging and Static content compression, but can be included.

        WindowsFeature DefaultDoc
        {
            Ensure          = "Present"
            Name            = "Web-Default-Doc"
            DependsOn       = '[WindowsFeature]IIS'
        }
        
        WindowsFeature DirectoryBrowsing
        {
            Ensure          = "Present"
            Name            = "Web-Dir-Browsing"
            DependsOn       = '[WindowsFeature]IIS'
        }

        WindowsFeature HTTPErrors
        {
            Ensure          = "Present"
            Name            = "Web-HTTP-Errors"
            DependsOn       = '[WindowsFeature]IIS'
        }

        WindowsFeature StaticContent
        {
            Ensure          = "Present"
            Name            = "Web-Static-Content"
            DependsOn       = '[WindowsFeature]IIS'
        }

        WindowsFeature HTTPLogging
        {
            Ensure          = "Present"
            Name            = "Web-HTTP-Logging"
            DependsOn       = '[WindowsFeature]IIS'
        }

        WindowsFeature StaticCompression
        {
            Ensure          = "Present"
            Name            = "Web-Stat-Compression"
            DependsOn       = '[WindowsFeature]IIS'
        }

        WindowsFeature RequestFiltering
        {
            Ensure          = "Present"
            Name            = "Web-Filtering"
            DependsOn       = '[WindowsFeature]IIS'
        }

        # Install the Application Development for PSWA

        WindowsFeature NetExtens4
        {
            Ensure          = "Present"
            Name            = "Web-Net-Ext45"
            DependsOn       = '[WindowsFeature]IIS'
        }

        WindowsFeature AspNet45
        {
            Ensure          = "Present"
            Name            = "Web-Asp-Net45"
            DependsOn       = '[WindowsFeature]IIS'
        }

        WindowsFeature ISAPIExt
        {
            Ensure          = "Present"
            Name            = "Web-ISAPI-Ext"
            DependsOn       = '[WindowsFeature]IIS'
        }

        WindowsFeature ISAPIFilter
        {
            Ensure          = "Present"
            Name            = "Web-ISAPI-filter"
            DependsOn       = '[WindowsFeature]IIS'
        }
        

        # Install the PSWA feature

        WindowsFeature PSWA
        {
            Ensure          = "Present"
            Name            = "WindowsPowerShellWebAccess"
            DependsOn       = @('[WindowsFeature]IIS','[WindowsFeature]AspNet45')
        }


        #Stop the default website
        
        
        cWebsite DefaultSite 
        {
            Ensure          = "Present"
            Name            = "Default Web Site"
            State           = "Stopped"
            PhysicalPath    = "C:\inetpub\wwwroot"
            DependsOn       = "[WindowsFeature]IIS"
        }
    

        # Create the new Application Pool 
       
        cAppPool PSWAPool 
        {
            Ensure                = "Present"
            Name                  = $PSWAppPoolName
            autoStart             = "true"  
            managedRuntimeVersion = "v4.0"
            managedPipelineMode   = "Integrated"
            startMode             = "AlwaysRunning"
            identityType          = "ApplicationPoolIdentity"
            restartSchedule       = @("18:30:00","05:00:00")
            DependsOn             = @('[WindowsFeature]IIS','[WindowsFeature]AspNet45') 

        }

        # Set permission for the app pool
        # How I used to do it in scripts
        # icacls.exe C:\Windows\web\PowerShellWebAccess\data\AuthorizationRules.xml /grant ('"' + "IIS AppPool\PWA_Pool" + '":R')

        cNTFSPermission AppPoolPermission
        {
            Ensure          = "Present"
            # Should be using "IIS AppPool\$PSWAAppPoolName" - but haven't got that to work yet
            Account         = "users"
            Access          = "Allow"
            Path            = "C:\Windows\web\PowerShellWebAccess\data\AuthorizationRules.xml"
            Rights          = 'ReadAndExecute'
            NoInherit       = $true
            DependsOn       = '[cAppPool]PSWAPool'
        } 

        
        # Create the new website for PSWA

        cWebsite PSWASite
        {
            Ensure          = "Present"
            Name            = $PSWASiteName
            State           = "Started"
            PhysicalPath    = "C:\Windows\web\PowerShellWebAccess\wwwroot"
            ApplicationPool = $PSWAAppPoolName
            BindingInfo     =  PSHOrg_cWebBindingInformation  
                             { 
                               Protocol              = "HTTPS" 
                               Port                  = 443 
                               Hostname              = "$PSWASiteName.Company.com"
                               CertificateThumbprint = "$certThumbprint"
                               CertificateStoreName  = "MY" 
                             } 
            DependsOn       = @('[cNTFSPermission]AppPoolPermission','[cAppPool]PSWAPool')

        }

        # My custom resource to add authorization rules
        cPSWAAuthorization Rule1 
        {

            Ensure          = 'Present'
            RuleName        = 'Rule1'
            Domain          = 'Company'
            Group           = 'Company\Domain Admins'
            ComputerName    = 's1.company.pri'
            Configuration   = '*' 
            DependsOn       = '[cWebsite]PSWASite'  

        }
    }
}

# Get the certificate Thumbprint
$cert=Invoke-Command -Computername s1 {Get-Childitem Cert:\LocalMachine\My | Where-Object {$_.FriendlyName -like "PSWA*"} | Select-Object -ExpandProperty ThumbPrint}
# Create the config
PWA -NodeName s1 -PSWASiteName PSWA -PSWAppPoolName PSWA_Pool -CertThumbPrint $cert -OutputPath c:\PWAConfig
# Push the config
Start-DscConfiguration -ComputerName s1 -Path C:\PWAConfig -Wait -Verbose -force