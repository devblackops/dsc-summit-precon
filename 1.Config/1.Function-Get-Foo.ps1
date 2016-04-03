
Function Get-Foo{
    Param(
        [Parameter(Mandatory=$true)]
        [string[]]$computerName
    )

    Get-Service -ComputerName $Computername -name bits
}

Break
Get-Foo -computerName s1,s2