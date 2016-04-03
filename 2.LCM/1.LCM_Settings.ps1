[DSCLocalConfigurationManager()]
Configuration LCM {	
	Param (
        [Parameter(Mandatory=$true)]
        [string[]]$ComputerName
    )

    Node $Computername
	{
		Settings # Hit Ctrl-Space for help
		{
            ConfigurationMode = 'ApplyAndAutoCorrect'
            RebootNodeIfNeeded = $true		
		}
	}
}

# Create the Computer.Meta.Mof in folder
LCM -computername s1,s2 -OutputPath .\




