#Requires -Version 4
#Requires -Module ActiveDirectory
#Requires -RunAsAdministrator
Param(
    [string]$UserName,
    [string]$ServerList=".\serverlist.txt",
    [string]$ProfileServerPath="\\Citrix-FileServer\e$\Shares\profiles\"
)

# This Requires delprof2 in the same path or %PATH%
# https://helgeklein.com/free-tools/delprof2-user-profile-deletion-tool/
if((Test-Path -Path "delprof2")){
    Write-Verbose "delprof2 found!"
}else{
    Write-Error -Message "delprof2 not found!"
    return $false
}

# Check that the serverlist is even accessible
if((Test-Path $ServerList)){
    $serverlist = Get-Content -Path $ServerList
}else{
    Write-Error -Message "File $($ServerList) is missing."
    return $false
}

# Check username is valid
if ($null -eq $UserName) {
    $UserName = Read-Host -Prompt "Enter Username"
}
if ($null -eq (Get-ADUser -Identity $UserName)) {
    Write-Error -Message "Username $($UserName) not found in Active Directory."
    return $false
}

# Delete/Remove profiles from servers
Remove-Profile -UserName $UserName -ServerList $ServerList

# Close file related to $UserName
Close-Files -UserName $UserName

#Get current date and format it
$Date = (Get-Date -Format "u").Replace(' ', '_').Replace('Z', '')

# Move user profile folder as backup
Rename-Item -Path "$($ProfileServerPath)$($Username)" -NewName "~$($Username).$($Date).old"

# Create user profile folder
New-Item -Path "$($ProfileServerPath)" -Name $Username -ItemType Directory

workflow Remove-Profile {
    param ([string]$UserName, [string[]]$ServerList, [number]$ThrottleLimit=10)
    <#
        Run delprof2 on each server in parallel for $UserName
        Default limit is 10 at a time
        To make this Powershell v3 compatible, remove "-throttlelimit $ThrottleLimit" from the foreach line and
          change the first line of this script to: #Requires -Version 3.
          Also probably a good thing to remove the ThrottleLimit Param.
    #>
    foreach -parallel -throttlelimit $ThrottleLimit ($server in $ServerList) {
        InlineScript { delprof2 /u /c:$server /id:$UserName }
    }
}

function Close-Files {
    param (
        [string]$UserName
     )
     net files | Where-Object { $_.Contains("$UserName") } | ForEach-Object { $_.Split( ' ' )[0] } | ForEach-Object { net file $_ /close }
     Start-Sleep -Seconds 5
     net files | Where-Object { $_.Contains("$UserName") } | ForEach-Object { $_.Split( ' ' )[0] } | ForEach-Object { net file $_ /close }
     Start-Sleep -Seconds 10
}
