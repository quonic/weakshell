$PowerCLIInstalled = Get-Module VMware.PowerCLI -ListAvailable
if($PowerCLIInstalled){
    $PSGallaryPowerCLI = Find-Module -Name VMware.PowerCLI
    if($PowerCLIInstalled.Version -eq $PSGallaryPowerCLI.Version){
        Write-Output "Lastest PowerCLI Installed"
    }else{
        Write-Output "PowerCLI not uptodate"
        Write-Output "Run for current user: Install-Module -Name VMware.PowerCLI -Scope CurrentUser"
        Write-Output "Run for all users:    Install-Module -Name VMware.PowerCLI -Scope AllUsers"
    }
}else{
    $VMwareModulesList = Get-Module VMware* -ListAvailable
    $VMwareModulesToRemove = @()
    $VMwareModulesList | ForEach-Object {
        $VMwareModulesToRemove += $_.Name
    }
    if($VMwareModulesToRemove){
        Write-Output "Please remove the following modules:"
        Write-Output $VMwareModulesToRemove
    }
    $HyperVModule = Get-Module Hyper* -ListAvailable
    $HyperVModuleToRemove = @()
    $HyperVModule | ForEach-Object {
        $VMwareModulesToRemove += $_.Name
    }
    if($VMwareModulesToRemove){
        Write-Output "Please remove the following modules:"
        Write-Output $VMwareModulesToRemove
    }
}
