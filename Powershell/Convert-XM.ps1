function Convert-XM {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false, ValueFromPipeline=$true)]
        $Files,
        [Parameter(Mandatory = $false)]
        $Path,
        [Parameter(Mandatory = $false)]
        $Codec = 'mp3',
        [Parameter(Mandatory = $false)]
        [string] $vlc
    )
    Begin
        {
            # Validate $Codec as only mp3, ogg, wav and flac work at this moment.
            if((-not ($Codec -eq 'mp3')) -and (-not ($Codec -eq 'ogg')) -and (-not ($Codec -eq 'wav')) -and (-not ($Codec -eq 'flac')))
            {
                Write-Error "Invalid Codec selected: $Codec / Only 'mp3','ogg','wav', and 'flac' accepted."
                Exit-PSSession
            }

            # Check if $vlc was set, if not then check if it is somewhere else
            if(-not $vlc)
            { 
                if(Test-Path 'C:\Program Files (x86)\VideoLAN\VLC\vlc.exe'){$vlc = 'C:\Program Files (x86)\VideoLAN\VLC\vlc.exe'}
                if(Test-Path 'C:\Program Files\VideoLAN\VLC\vlc.exe'){$vlc = 'C:\Program Files\VideoLAN\VLC\vlc.exe'}
                if($vlc -eq $null){
                    Write-Error "Quiting cant find VLC"
                    Exit-PSSession
                    }
            }
            if($Path)
            {
                $list = Get-ChildItem "$Path\*" -recurse -include *.it,*.xm,*.mod
            }
            else
            {
                $list = $Files
            }



            Write-Host 'Hold "q" to quit...'
        
            # Need to set this to 1 or else windows will fill the screen with the app not responding windows.
            # If this script fails then you will need to set it back to 0 if you 
            $prop_wre = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\Windows Error Reporting'

            if($prop_wre.DontShowUI -eq 0)
            {
                $prop_wre.DontShowUI = 1
            }
        }
    Process
        {
            
            if ($PSBoundParameters.ContainsKey('Verbose'))
            {
                Convert-AllTheMusics -Files $list -Type $Codec -Vlc $vlc -JobName "ModConvert" -Verbose
            }
            else
            {
                Convert-AllTheMusics -Files $list -Type $Codec -Vlc $vlc -JobName "ModConvert"
            }

            if(-not ($baderror -eq $null))
            {
                Write-Error "Something fucked up, exiting."
                Exit-PSSession
            }

            Write-Verbose "All Done! Now don't try to stop me...." -Background DarkRed
            $prop_wre.DontShowUI = 0
        }
    }



workflow Convert-AllTheMusics
{
[CmdletBinding()]
Param
    (
        # Array of files to convert
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        $Files,

        # Extention to convert to
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        $Type,

        # Need path and file to vlc to convert
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        $Vlc
    )
    ForEach –parallel -throttlelimit 2 ($i in $Files) {
        inlinescript
        {
            $codec = 'mp3'
            $k = $Using:i
            $exe = $Using:Vlc
            $newFile = $k.FullName.Replace("'", "\'").Replace($k.Extension, ".$codec")
            Write-Verbose "Found $k"

            if ( -not (Test-Path $newFile)){
                $output1 = "-I dummy " + $k + " :sout=#transcode{acodec=" + $codec + ",vcodec=dummy}:standard{access=file,mux=raw,dst='" + $newFile +"'} --play-and-exit"
                Write-Verbose "$exe $output1"
                $lastCPU = 1000.0
                $elapsed = [System.Diagnostics.Stopwatch]::StartNew()
                $process = Start-Process "$exe" "$output1" -PassThru -WindowStyle Hidden
                do {
                    Write-Verbose "Process: $($process.Id) / $($process.CPU)% / Responding: $($process.Responding)"
                    if($process.CPU -eq $lastCPU){Stop-Process $process.Id -ErrorAction SilentlyContinue}
                    $lastCPU = $process.CPU
                    Start-Sleep -Milliseconds 1000
                } until (($process.HasExited -eq $true) -or ($($elapsed.Elapsed.Seconds) -gt 120) -or ($process.CPU -gt 100))
            }
            # Uncomment the next line when you're sure everything is working right
            #Remove-Item $_.FullName.Replace('[', '`[').Replace(']', '`]')
        }
    }
}


