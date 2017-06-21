function Invoke-IndexUpdate {
    [CmdletBinding()]
    param (

    )
    $Drives = $(Get-PSdrive -PSProvider FileSystem | Where-Object {-not $_.DisplayRoot}).Root
    $Drives | Get-ChildItem -Recurse -Force | Select-Object -Property FullName | Out-File -FilePath $env:USERPROFILE\.PSIndex
}

function Get-IndexedItem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Item
    )
    
    begin {
        if (Test-Path $env:USERPROFILE\.PSIndex) {
            Write-Debug -Message "Found .PSIndex"
        }
        else {
            Write-Debug -Message "Not Found .PSIndex"
            Invoke-IndexUpdate
        }
    }
    
    process {
        $SearchForItem = $_
        $LocatedItems = Get-Content -Path $env:USERPROFILE\.PSIndex | ForEach-Object {
            if($_ -like $SearchForItem){
                $_
            }
        }
        #Where-Object {$_ -like $SearchForItem}
    }
    
    end {
        if ($LocatedItems.Count -gt 0) {
            return $LocatedItems
        }
        else {
            return 0
        }
    }
}

#Export-ModuleMember -Function 'Invoke-IndexUpdate','Get-IndexedItem'

#Invoke-IndexUpdate
Get-IndexedItem -Item "hiberfil.sys"