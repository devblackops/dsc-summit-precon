Configuration InstallSnmp{

    Param (
        [Parameter(Mandatory=$true)]
        [string[]]$ComputerName
    )

    Node $ComputerName {
        WindowsFeature SNMP {

            Name = 'SNMP-Service'
            Ensure = 'Present'
        }
    }
}

InstallSNMP -ComputerName s1 -OutputPath .\