Install-Module -Name VMware.PowerCLI -Scope CurrentUser
Import-Module VMware.PowerCLI

Connect-VIServer -Server "vCenterName"

$vms = @(
    "Server1"
    "Server2"
    "Server3"
)
    
#Update VMtools without reboot
$reboot = $false
    
$vms | ForEach-Object {
    Write-Progress -Activity "Upgrading VMware Tools" -PercentComplete $(-1) -CurrentOperation "Upgrade Tools"
    $vm = Get-VM $_ -ErrorAction SilentlyContinue -ErrorVariable getVMError
    if ($vm.Count -eq 1) {
        if ($vm.PowerState -eq "PoweredOff") {
            Start-VM -VM $vm
            $VMRebootStatus = 1..24 | ForEach-Object {
                Write-Progress -Activity "Waiting for $($vm.Name) to boot" -PercentComplete ((100 / 24) * $_) -CurrentOperation "Booting"
                Start-Sleep -Seconds 10
                if ((Get-VM $vm).extensionData.Guest.ToolsStatus -eq "toolsOK") {
                    return $true
                }
                elseif ((Get-VM $vm).extensionData.Guest.ToolsStatus -ne "toolsOK" -and $_ -ge 24) {
                    return $false
                }
            }
            if ($VMRebootStatus) {
                Write-Progress -Activity "Waiting for $($vm.Name) to boot" -Completed -CurrentOperation "Booting"
            }
            else {
                Write-Progress -Activity "Waiting for $($vm.Name) to boot" -Completed -CurrentOperation "Booting"
                Write-Error -Message "$($vm.Name) failed to boot or VMware Tools not working correctly."
                return @{
                    VM      = $_
                    Updated = $false
                    Reason  = "$($vm.Name) failed to boot or VMware Tools not working correctly."
                }
            }
        }

        if ($reboot) {
            $vm | Update-Tools -ErrorAction SilentlyContinue -ErrorVariable updateError
        }
        else {
            $vm | Update-Tools –NoReboot -ErrorAction SilentlyContinue -ErrorVariable updateError
        }

        if ($updateError) {
            Write-Error "Failed to Update $_"
        }
        if (-not $updateError -and -not $getVMError) {
            Write-Information "Updated $_ ------ "
            return @{
                VM      = $_
                Updated = $true
                Reason  = "Updated $_"
            }
        }
    }
    else {
        Write-Error "Failed to find or more than one VM named '$_'"
        return @{
            VM      = $_
            Updated = $false
            Reason  = "Failed to find or more than one VM named '$_'"
        }
    }
}
Write-Progress -Activity "Upgrading VMware Tools" -Completed -CurrentOperation "Upgrade Tools"