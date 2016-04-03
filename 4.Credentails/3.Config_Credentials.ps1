$ConfigData = @{
        AllNodes = @(
            @{
                NodeName='s2'
                # PSDscAllowPlainTextPassword=$True
                CertificateFile = 'c:\cert\ClientAuth.cer' # <--------------
                ThumbPrint = '04D218B75F4F437D6DDB62F3CC136582CA9BF5FF'
               
            }
        )
}


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

CreateDir -computername s2 -Credential (Get-Credential) -OutputPath .\ -ConfigurationData $ConfigData

