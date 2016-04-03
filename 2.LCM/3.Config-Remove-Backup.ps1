Configuration InstallSoftware{
    Param (
        [Parameter(Mandatory=$true)]
        [string[]]$ComputerName
    )
    Node $ComputerName {
        WindowsFeature Backup {
            Name = 'Windows-Server-Backup'
            Ensure = 'Absent' # OVER HERE! OVER HERE!
        }
    }
}

InstallSoftware -ComputerName S1 -OutputPath .\