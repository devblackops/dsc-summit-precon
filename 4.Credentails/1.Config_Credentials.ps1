Configuration CreateDir {
    Param (
        [Parameter(Mandatory=$true)]
        [string[]]$ComputerName,
        [Parameter(Mandatory=$true)]
        [PSCredential]$Credential
    )

    Import-DscResource -modulename 'PSDesiredStateConfiguration'

    Node $ComputerName {
        File MakeDir {
            DestinationPath = 'c:\DirTest'
            Type = 'Directory'
            Ensure = 'Present'
            Credential = $Credential
        }
    }
}

CreateDir -computername s2 -Credential (Get-Credential) -OutputPath .\
