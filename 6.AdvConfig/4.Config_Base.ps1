configuration BaseConfig {
    param (
        
        [string]$ServiceName

    )
    # There is no Node <------------------------------------

        Service StartService {
            Name = $serviceName
            State = 'Running'
            Ensure = 'Present'
        }
        WindowsFeature Backup {
            Name = 'Windows-server-backup'
            Ensure = 'Present'

        } 
}

# Save as BaseConfig.schema.psm1

