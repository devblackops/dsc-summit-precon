[DSCLocalConfigurationManager()]
Configuration LCM 
{
	Param (
        [Parameter(Mandatory=$true)]
        [string[]]$ComputerName,
        [Parameter(Mandatory=$true)]
        [string]$ThumbPrint
    )

    Node $ComputerName {
		Settings
		{
			AllowModuleOverwrite = $True
            ConfigurationMode = 'ApplyAndAutoCorrect'
			RefreshMode = 'Push'
            CertificateID = "$ThumbPrint"
                        	
		}
	}
}

$ThumbPrint=Invoke-Command -ComputerName s2 {Get-ChildItem -Path cert:\localMachine\my | Where-Object {$_.EnhancedKeyUsageList -like "*Document Encryption*"} | Select-Object -ExpandProperty ThumbPrint}

LCM -ComputerName s2 -Thumbprint $ThumbPrint -OutputPath .\






