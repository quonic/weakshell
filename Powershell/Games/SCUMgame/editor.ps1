#Requires -Module PSSQLite
function Set-Stats {
    <#
.SYNOPSIS
    Changes the character's stats
.DESCRIPTION
    This will change the specified charater to thhe stats you wish.
    Without specifying a stat, this will default to 5.
    Without specifying skills, this will default to 4.
.EXAMPLE
    PS C:\> Set-Stats -ProfileName "Bob" -Dexterity 4
    This will set Dexterity to 4 for the character named Bob
.EXAMPLE
    PS C:\> Set-Stats -ProfileName "Bob" -Skills 2
    This will set all skills to 2 for the character named Bob
.NOTES
    Requires the module PSSQLite to be installed.
    Install with:
        Install-Module -Name "PSSQLite" -Scope CurrentUser
    Updated for 9/2 patch.

#>
    param(
        [Alias('Name')]
        [string]
        $ProfileName,
        [Alias('str')]
        [ValidateRange(0, 5)]
        [int]
        $Strength = 5,
        [Alias('con')]
        [ValidateRange(0, 5)]
        [int]
        $Constitution = 5,
        [Alias('int')]
        [ValidateRange(0, 5)]
        [int]
        $Intelligence = 5,
        [Alias('dex')]
        [ValidateRange(0, 5)]
        [int]
        $Dexterity = 5,
        [ValidateRange(0, 5)]
        [int]
        $Skills = 4
    )

    $sqlsplat = @{
        Datasource = "C:\Users\$($env:USERNAME)\AppData\Local\SCUM\Saved\SaveFiles\SCUM.db"
    }
    $userprofiles = Invoke-SqliteQuery @sqlsplat -Query "select * from user_profile"
    if ($ProfileName) {
        $prisoner_id = ($userprofiles|Where-Object {$_.name -eq $ProfileName}).prisoner_id
    }
    else {
        $prisoner_id = $userprofiles.prisoner_id
    }

    $prisoner_id | ForEach-Object {
        $This_prisoner_id = $_
        $prisoner = Invoke-SqliteQuery @sqlsplat -Query "select * from prisoner where id = $This_prisoner_id"
        [xml]$prisoner_xml = $prisoner.xml -replace "`0", "`n`r"
        $prisoner_xml.Prisoner.LifeComponent.CharacterAttributes._strength = [string]$Strength
        $prisoner_xml.Prisoner.LifeComponent.CharacterAttributes._constitution = [string]$Constitution
        $prisoner_xml.Prisoner.LifeComponent.CharacterAttributes._intelligence = [string]$Intelligence
        $prisoner_xml.Prisoner.LifeComponent.CharacterAttributes._dexterity = [string]$Dexterity
        $prisoner_xml.Prisoner.LifeComponent.AttributeHistoryStrength.Attribute | ForEach-Object {$_._value = [string]$Strength}
        $prisoner_xml.Prisoner.LifeComponent.AttributeHistoryConstitution.Attribute | ForEach-Object {$_._value = [string]$Constitution}
        $prisoner_xml.Prisoner.LifeComponent.AttributeHistoryIntelligence.Attribute | ForEach-Object {$_._value = [string]$Intelligence}
        $prisoner_xml.Prisoner.LifeComponent.AttributeHistoryDexterity.Attribute | ForEach-Object {$_._value = [string]$Dexterity}
        $prisoner = Invoke-SqliteQuery @sqlsplat -Query "update prisoner set xml = '$($prisoner_xml.OuterXml  -replace "`n`r","`0")' where id = $This_prisoner_id;"

        $prisoner_skill = Invoke-SqliteQuery @sqlsplat -Query "select * from prisoner_skill where prisoner_id = $This_prisoner_id"
        $prisoner_skill | ForEach-Object {
            [xml]$prisoner_skill_xml = $_.xml -replace "`0", ''
            $prisoner_skill_xml.Skill._level = [string]$Skills
            $prisoner_skill_xml.Skill._experiencePoints = "9999"
            $sqlwhere = "where prisoner_id = $This_prisoner_id and name = '$($prisoner_skill_xml.Skill.'#text')'"
            $Query = "update prisoner_skill set level = $([string]$Skills), experience = '10000', xml = '$($prisoner_skill_xml.OuterXml)' $sqlwhere;"
            try {
                Invoke-SqliteQuery @sqlsplat -Query $Query
            }
            catch {
                throw "error"
            }
        }
    }
}


function Get-SCUMItems {
    param (
        [ValidateScript( {Test-Path -Path $_})]
        [string]
        $Path = "C:\Users\$($env:USERNAME)\AppData\Local\SCUM\"
    )
    $DataFile = Join-Path -Path $Path -ChildPath "ItemData.clixml"
    if (Test-Path -Path $DataFile) {
        $ItemData = Import-Clixml -Path $DataFile
    }
    else {
        $ItemData = $null
    }
    $sqlsplat = @{
        Datasource = "C:\Users\$($env:USERNAME)\AppData\Local\SCUM\Saved\SaveFiles\SCUM.db"
    }
    $userprofiles = Invoke-SqliteQuery @sqlsplat -Query "select * from user_profile"
    $prisoner_id = $userprofiles.prisoner_id
    $InventoryItems = $prisoner_id | ForEach-Object {
        $This_prisoner_id = $_
        $prisoner = Invoke-SqliteQuery @sqlsplat -Query "select * from prisoner where id = $This_prisoner_id"
        [xml]$prisoner_xml = $prisoner.xml -replace "`0", ''
        # Output Items
        
        if ($ItemData) {$ItemData}

        # Items on back
        $prisoner_xml.Prisoner.InventoryComponent.ChildNodes |
            Where-Object {$_.Inventory.Width -eq 0 -and $_.Inventory.Height -eq 0}
        
        foreach ($item in $prisoner_xml.Prisoner.InventoryComponent.ChildNodes) {
            $Count = $item.Inventory.InventorySlots._count
            for ($i = 0; $i -lt $($Count - 1); $i++) {
                $item.Inventory.InventorySlots."InventorySlot$i"
            }
        }
        
        # Held Items
        $prisoner_xml.Prisoner.AttachedItems.ChildNodes |
            Where-Object {$_.Inventory.Width -eq 0 -and $_.Inventory.Height -eq 0}
        
        foreach ($item in $prisoner_xml.Prisoner.AttachedItems.ChildNodes) {
            $Count = $item.Inventory.InventorySlots._count
            for ($i = 0; $i -lt $($Count - 1); $i++) {
                $item.Inventory.InventorySlots."InventorySlot$i"
            }
        }
    }
    $InventoryItems | Where-Object {$null -ne $_.'#text'} | Sort-Object -Property '#text' -Unique
}

function Export-SCUMItems {
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object[]]
        $InputObject,
        [ValidateScript( {Test-Path -Path $_})]
        [string]
        $Path = "C:\Users\$($env:USERNAME)\AppData\Local\SCUM\"
    )
    $DataFile = Join-Path -Path $Path -ChildPath "ItemData.json"
    $InputObject | ConvertTo-Json | Out-File -FilePath $DataFile
}

# $Path = "C:\Users\$($env:USERNAME)\AppData\Local\SCUM\"
# $DataFile = Join-Path -Path $Path -ChildPath "ItemData.json"
# Remove-Item -Path $DataFile
# Get-SCUMItems | Export-SCUMItems


# Get-SCUMItems

function Get-Character {
    param ()
    $sqlsplat = @{
        Datasource = "C:\Users\$($env:USERNAME)\AppData\Local\SCUM\Saved\SaveFiles\SCUM.db"
    }
    $userprofiles = Invoke-SqliteQuery @sqlsplat -Query "select * from user_profile"
    $prisoner_id = $userprofiles.prisoner_id
    $prisoner_id | ForEach-Object {
        $This_prisoner_id = $_
        $prisoner = Invoke-SqliteQuery @sqlsplat -Query "select * from prisoner where id = $This_prisoner_id"
        [xml]$prisoner_xml = $prisoner.xml -replace "`0", ''
        $prisoner_xml.OuterXml
    }
}

function Set-Character {
    param (
        [string]
        $Name,
        [string]
        $XmlData
    )
    $sqlsplat = @{
        Datasource = "C:\Users\$($env:USERNAME)\AppData\Local\SCUM\Saved\SaveFiles\SCUM.db"
    }
    try {
        [xml]$XmlTest = $XmlData    
    }
    catch {
        throw "Bad XML"
    }
    
    try {
        $userprofiles = Invoke-SqliteQuery @sqlsplat -Query "select * from user_profile where name = '$Name'"
        if ($userprofiles.Count -eq 0) {
            throw "Bad Username"
        }
    }
    catch {
        throw "Bad username"
    }
    
    $prisoner_id = $userprofiles.prisoner_id
    Invoke-SqliteQuery @sqlsplat -Query "update prisoner set xml = '$XmlData' where id = $prisoner_id;"
}


Get-Character | Out-File -FilePath "C:\Users\$($env:USERNAME)\AppData\Local\SCUM\$($env:USERNAME)-$([guid]::NewGuid()).xml"
