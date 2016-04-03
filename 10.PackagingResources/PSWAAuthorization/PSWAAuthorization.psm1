#requires -version 5.0


enum Ensure {

    Absent
    Present
}

[DscResource()]
class PSWAAuthorization {
    
    [DscProperty(Key)]
    [string]$RuleName

    [DscProperty(Mandatory)]
    [Ensure] $Ensure

    [DscProperty(Mandatory)]
    [string] $Domain

    [DscProperty(Mandatory)]
    [string] $ComputerName

    [DscProperty(Mandatory)]
    [string] $Group

    [DscProperty(Mandatory)]
    [string] $Configuration

    [PSWAAuthorization] Get() {
    
        Write-Verbose "[$(Get-Date)] Starting Get method"
        $result=Get-PswaAuthorizationRule -RuleName $this.RuleName -ErrorAction silentlycontinue
        $Test=[Hashtable]::New()
        $test.Add('RuleName',$Result.RuleName)
        $test.Add('User',$Result.User)
        $test.Add('Destination',$Result.Destination)
        $test.Add('ConfigurationName',$Result.ConfigurationName)
        Write-Verbose "[$(Get-Date)] Ending Get method"
        
        return $Test
    }

    [void] Set() {
        
        Write-Verbose "[$(Get-Date)] Starting Set method"
        Write-verbose "Adding new rule"

        Add-PswaAuthorizationRule -UserGroupName $this.Group -ComputerName $this.ComputerName -ConfigurationName $this.Configuration -RuleName $this.RuleName -Force
        Write-Verbose "[$(Get-Date)] Ending Set method"
    }

    [bool] Test() {

            Write-Verbose "[$(Get-Date)] Starting Test method"
            $result=Get-PswaAuthorizationRule -RuleName $this.RuleName -ErrorAction silentlycontinue
            $computer = "$($this.Domain)\$($this.ComputerName)" -replace '.company.pri',''
          
    
            If ($result.user -eq $this.Group -and $result.Destination -eq $Computer) {
                Write-verbose "Test for rule passed - nothing to configure"
                Return $true
            }Else {
                Write-Verbose "Test for Rule failed - need to Set"
                Return $False

            Write-Verbose "[$(Get-Date)] Ending Test method"

            }
    }
        
}
   
            
 