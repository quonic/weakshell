function Remove-MBSAReports {
    [CmdletBinding()]
    Param()
    Write-Verbose -Message "Removing old reports from $($Env:USERPROFILE)\SecurityScans\"
    Get-ChildItem "$($Env:USERPROFILE)\SecurityScans\*" -Recurse -ea 'SilentlyContinue' | Remove-Item -Force -Recurse
}

function Invoke-MBSAScan {
    [CmdletBinding()]
    Param()
    $exembsacli = '\Program Files\Microsoft Baseline Security Analyzer 2\mbsacli.exe'
    $mbsacli = $null
    # Look for where mbsacli.exe is installed
    #  Restrict to FileSystem type PSDrive's
    $Drives = Get-PSdrive -PSProvider FileSystem
    $Drives | ForEach-Object {
        $Drive = "$($_.Name):\"
        $Root = $_.Root
        # We don't want to look on any shared drives
        if (-not ($Root.Substring(0, 2) -like '\\')) {
            if (Test-Path -Path "$($Drive)$($exembsacli)") {
                Write-Verbose -Message "Found mbsacli.exe located on $($Drive)"
                $mbsacli = "$($Drive)$($exembsacli)"
                break
            }
        }
    }
    # MBSA wasn't found, probably not installed
    if (-not $mbsacli) {
        throw "MBSA Not installed"
    }
    if ($Verbose) {
        & $mbsacli /d $($env:USERDOMAIN) /n os+iis+sql+password /wi /nvc /o %C%
    }
    else {
        & $mbsacli /d $($env:USERDOMAIN) /n os+iis+sql+password /wi /nvc /o %C% 2>&1> $null
    }
}

function Save-MBSAReport {
    [CmdletBinding()]
    Param(
        [string]
        $Path
    )
    if ($Path) {
        $reportfile = $Path
    }
    else {
        $time = Get-Date
        $timeFormated = "$($time.Year)-$($time.Month)-$($time.Day)-$($time.Hour)-$($time.Minute)"
        $reportfile = "$($Env:USERPROFILE)\Desktop\MBSA-Report-$timeFormated.csv"
    }
    Write-Verbose -Message "Saving report to $reportfile"
    Write-Verbose -Message "Getting all mbsa reports under $($Env:USERPROFILE)\SecurityScans\"
    $Reports = Get-ChildItem -Path "$($Env:USERPROFILE)\SecurityScans\*.mbsa"
    if ($Reports) {
        $Reports | ForEach-Object {
            [xml]$ScanResults = Get-Content $_
            $Machine = $ScanResults.SecScan.Machine
            Write-Verbose -Message "Getting Updates for $Machine"
            $SingleMachine = $ScanResults.SecScan.Check | ForEach-Object {
                $_.Detail.UpdateData
            } | ForEach-Object {
                if ($_.IsInstalled) {
                    Write-Verbose -Message "Update $($_.KBID) installed."
                }
                else {
                    Write-Verbose -Message "Update $($_.KBID) not installed."
                    $data = New-Object -TypeName psobject
                    $data | Add-Member -MemberType NoteProperty -Name "Machine" -Value $Machine
                    $data | Add-Member -MemberType NoteProperty -Name "Title" -Value $($_.Title)
                    $data | Add-Member -MemberType NoteProperty -Name "KBID" -Value $($_.KBID)
                    Write-Output $data
                }
            }
            Write-Output $SingleMachine
        } | Export-Csv -Path $reportfile -NoTypeInformation
    }
    else {
        Write-Error -Message "No reports found."
    }
    
}

Clear-Host
Remove-MBSAReports
Invoke-MBSAScan -Verbose
Save-MBSAReport -Verbose

