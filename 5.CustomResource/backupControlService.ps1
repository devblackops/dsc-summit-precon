#requires -version 5.0

# Defines the values for the resource's Status property.
enum Ensure {

    Absent
    Present
}

enum Status {

    Running
    Stopped
}

# [DscResource()] indicates the class is a DSC resource.
[DscResource()]
class ControlService {
    
    # A DSC resource must define at least one key property
    [DscProperty(Key)]
    [string]$ServiceName

    [DscProperty(Mandatory)]
    [Ensure] $Ensure

    [DscProperty(Mandatory)]
    [string] $State

 
    [ControlService]Get() {

        Write-Verbose "[$(Get-Date)] Starting Get method"
        $Service=Get-service -name $this.ServiceName
        $Test=[Hashtable]::New()
        $test.Add('ServiceName',$Service.Name)
        $test.Add('State',$Service.Status)
        $test.Add('Ensure',$This.Ensure)
        Write-Verbose "[$(Get-Date)] Ending Get method"
        
        return $Test
    }

    [void] Set() {
        
        Write-Verbose "[$(Get-Date)] Starting Set method"
        Write-verbose "Setting Service $this.ServiceName to $this.State"

        Set-Service -Name $this.ServiceName -Status $this.State

        Write-Verbose "[$(Get-Date)] Ending Set method"
    } # End Set

    [bool] Test() {

            Write-Verbose "[$(Get-Date)] Starting Test method"
            Write-Verbose "Target status is $($this.status)"    
            
            $result=Get-Service -Name $this.ServiceName
        
            If ($result.Status -eq $this.Status) {
                Write-Verbose "Actual result is $($result.status)"
                Write-verbose "Nothing to configure"
                Return $true
            }Else {
                Write-Verbose "Actual result is $($result.status)"
                Write-Verbose "Need to Set"
                Return $False
            }
        Write-Verbose "[$(Get-Date)] Ending Test method"
        } # End Test             
} # End Class
   
            
     