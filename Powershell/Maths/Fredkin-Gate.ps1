# https://en.wikipedia.org/wiki/Fredkin_gate
# My implimentaion of a Fredkin Gate in PowerShell

function Get-Fredkin {
    [CmdletBinding()]
    param (
        [Alias("C")]
        [boolean]$InputC=$false,
        [Alias("I1")]
        [boolean]$Input1=$false,
        [Alias("I2")]
        [boolean]$Input2=$false
    )
    
    begin {
    }
    
    process {
        # O1 = (NOT C AND I1) OR (C AND I2)
        $Output1 = (-not $InputC -and $Input1) -or ($InputC -and $Input2)
        # O2 = (C AND I1) OR (NOT C AND I2)
        $Output2 = ($InputC -and $Input1) -or (-not $InputC -and $Input2)

        $Output = New-Object -TypeName PSCustomObject -Property @{
            C  = $InputC
            O1 = $Output1
            O2 = $Output2
        }
    }
    
    end {
        $Output
    }
}

# Test if Get-Fredkin works correctly.
# If there is no output, then it is working correctly.

$truetable = @(
	@{InputC = $false;Input1 = $false;Input2 = $false},
    @{InputC = $false;Input1 = $false;Input2 = $true},
    @{InputC = $false;Input1 = $true;Input2 = $false},
    @{InputC = $false;Input1 = $true;Input2 = $true},
    @{InputC = $true;Input1 = $false;Input2 = $false},
    @{InputC = $true;Input1 = $false;Input2 = $true},
    @{InputC = $true;Input1 = $true;Input2 = $false},
    @{InputC = $true;Input1 = $true;Input2 = $true}
)

$returnedData = $truetable | ForEach-Object {
    $splat = $_
    
    $Data = Get-Fredkin @splat
    Write-Output @($($_.InputC),$($_.Input1),$($_.Input2),$($Data.C),$($Data.O1),$($Data.O2))
}

Compare-Object @($false,$false,$false,$false,$false,$false) @($returnedData[0],$returnedData[1],$returnedData[2],$returnedData[3],$returnedData[4],$returnedData[5])
Compare-Object @($false,$false,$true,$false,$false,$true) @($returnedData[6],$returnedData[7],$returnedData[8],$returnedData[9],$returnedData[10],$returnedData[11])
Compare-Object @($false,$true,$false,$false,$true,$false) @($returnedData[12],$returnedData[13],$returnedData[14],$returnedData[15],$returnedData[16],$returnedData[17])
Compare-Object @($false,$true,$true,$false,$true,$true) @($returnedData[18],$returnedData[19],$returnedData[20],$returnedData[21],$returnedData[22],$returnedData[23])
Compare-Object @($true,$false,$false,$true,$false,$false) @($returnedData[24],$returnedData[25],$returnedData[26],$returnedData[27],$returnedData[28],$returnedData[29])
Compare-Object @($true,$false,$true,$true,$true,$false) @($returnedData[30],$returnedData[31],$returnedData[32],$returnedData[33],$returnedData[34],$returnedData[35])
Compare-Object @($true,$true,$false,$true,$false,$true) @($returnedData[36],$returnedData[37],$returnedData[38],$returnedData[39],$returnedData[40],$returnedData[41])
Compare-Object @($true,$true,$true,$true,$true,$true) @($returnedData[42],$returnedData[43],$returnedData[44],$returnedData[45],$returnedData[46],$returnedData[47])

