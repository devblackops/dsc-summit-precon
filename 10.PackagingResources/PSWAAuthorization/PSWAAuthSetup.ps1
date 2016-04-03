# Ise C:\pwa\cPSWAAuthorization\cPSWAAuthorization.psm1

New-ModuleManifest -Path C:\pwa\cPSWAAuthorization\cPSWAAuthorization.psd1 -RootModule cPSWAAuthorization.psm1 `
    -Guid ([GUID]::NewGuid()) -ModuleVersion 1.0 -Author 'Jason Helmick' `
    -Description 'PSWA Rule Authorization' -DscResourcesToExport 'cPSWAAuthorization' 
    
# ise C:\pwa\cPSWAAuthorization\cPSWAAuthorization.psd1

