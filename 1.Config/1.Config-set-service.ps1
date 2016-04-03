Configuration ServiceBits{
    Param (
        [Parameter(Mandatory=$true)]
        [string[]]$ComputerName
    )
    Node $ComputerName {
        Service bits {
            Name='bits'
            State='running'
        }
    }
}

Break
ServiceBits -ComputerName S1,S2 -OutputPath .\