Configuration ConfigService {
    Param (
        [Parameter(Mandatory=$true)]
        [string[]]$ComputerName,
        [Parameter(Mandatory=$true)]
        [string]$Servicename,
        [Parameter(Mandatory=$true)]
        [string]$State
    )

    Import-DSCResource -ModuleName ControlService
    
    Node $ComputerName {
        ControlService bits {

            Servicename = $servicename
            State = $State
            Ensure = 'Present'

        }

    }

}

Configservice -Computername Client -servicename bits -State running -Output .\
