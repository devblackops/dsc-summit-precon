$ConfigData = @{
    AllNodes = @(
        @{
            NodeName='s1'
            PSDscAllowPlainTextPassword=$True
        }
    )
}

##############################################################
# Ignore above the line until the next chpater




Configuration CreateDC{
    Param (
        [Parameter(Mandatory=$true)]
        [string[]]$ComputerName,
        [Parameter(Mandatory=$true)]
        [PSCredential]$Credential
    )

    Import-DscResource -Name xADDomainController
    # Import-DscResource -ModuleName xActiveDirectory #How to load them all
    # Import-DscResource -ModuleName PSDesiredStateConfiguration # To Prevent warning message

    Node $ComputerName {

        WindowsFeature ADSoftware { 
            Name = 'AD-Domain-Services'
            Ensure = 'Present'
        }

        xADDomainController SecondDC {
            DomainAdministratorCredential = $Credential
            DomainName = 'Company.pri'
            SafemodeAdministratorPassword = $Credential
            DependsOn = '[WindowsFeature]ADSoftware' # <----------------------
        }

    } #End Node
       
} #End Config

CreateDC -ComputerName S1 -Credential (Get-Credential) -OutputPath .\ -ConfigurationData $ConfigData