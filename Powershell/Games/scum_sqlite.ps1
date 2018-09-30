#Requires -Module PSSQLite
param(
    [Alias('Name','')]
    [string]
    $ProfileName
)
<#
Updated for 9/2 patch
#>
<#
For the game SCUM. This sets stats too 5 and skills to 4 for specified character.
Singleplayer only and run when the game isn't running

Requirements:
Install the module PSSQLite
Copy the line below and run it in powershell
 Install-Module -Name "PSSQLite" -Scope CurrentUser

Then run this script from powershell. Replace ThisProfileName with your character in single player

.\scum_sqlite.ps1 -ProfileName 'ThisProfileName'

or if you want to update all profiles just run the following

.\scum_sqlite.ps1

#>

$sqlsplat = @{
    Datasource = "C:\Users\$($env:USERNAME)\AppData\Local\SCUM\Saved\SaveFiles\SCUM.db"
}
$userprofiles = Invoke-SqliteQuery @sqlsplat -Query "select * from user_profile"
if($ProfileName){
    $prisoner_id = ($userprofiles|Where-Object {$_.name -eq $ProfileName}).prisoner_id
}else {
    $prisoner_id = $userprofiles.prisoner_id
}

$prisoner_id | ForEach-Object {
    $This_prisoner_id = $_
    $prisoner = Invoke-SqliteQuery @sqlsplat -Query "select * from prisoner where id = $This_prisoner_id"
    [xml]$prisoner_xml = $prisoner.xml -replace "`0",''
    $prisoner_xml.Prisoner.LifeComponent.CharacterAttributes._strength = "5"
    $prisoner_xml.Prisoner.LifeComponent.CharacterAttributes._constitution = "5"
    $prisoner_xml.Prisoner.LifeComponent.CharacterAttributes._intelligence = "5"
    $prisoner_xml.Prisoner.LifeComponent.CharacterAttributes._dexterity = "5"
    $prisoner_xml.Prisoner.LifeComponent.AttributeHistoryStrength.Attribute | ForEach-Object {$_._value = "5"}
    $prisoner_xml.Prisoner.LifeComponent.AttributeHistoryConstitution.Attribute | ForEach-Object {$_._value = "5"}
    $prisoner_xml.Prisoner.LifeComponent.AttributeHistoryDexterity.Attribute | ForEach-Object {$_._value = "5"}
    $prisoner_xml.Prisoner.LifeComponent.AttributeHistoryIntelligence.Attribute | ForEach-Object {$_._value = "5"}
    $prisoner = Invoke-SqliteQuery @sqlsplat -Query "update prisoner set xml = '$($prisoner_xml.OuterXml)' where id = $This_prisoner_id;"

    $prisoner_skill = Invoke-SqliteQuery @sqlsplat -Query "select * from prisoner_skill where prisoner_id = $This_prisoner_id"
    $prisoner_skill | Where-Object {$_.level -ne "4"} | ForEach-Object {
        [xml]$prisoner_skill_xml = $_.xml -replace "`0", ''
        $prisoner_skill_xml.Skill._level = "4"
        $prisoner_skill_xml.Skill._experiencePoints = "10000000"
        $sqlwhere = "where prisoner_id = $This_prisoner_id and name = '$($prisoner_skill_xml.Skill.'#text')'"
        $Query = "update prisoner_skill set level = 4, experience = '10000000', xml = '$($prisoner_skill_xml.OuterXml)' $sqlwhere;"
        try {
            Invoke-SqliteQuery @sqlsplat -Query $Query
        }
        catch {
            throw "error"
        }
    }
}