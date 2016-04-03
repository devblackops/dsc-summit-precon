Configuration StartSoftware{
    Param (
        [Parameter(Mandatory=$true)]
        [string[]]$ComputerName
    )
    Node $ComputerName {
       WindowsProcess Notepad {
           Path = 'notepad.exe'
           Arguments = ''
       }

       WindowsProcess MSPaint {
           Path = 'mspaint.exe'
           Arguments = ''
       }

    }
}

StartSoftware -ComputerName Client -OutputPath .\