<#
.Synopsis
   Saves the stream specified
.DESCRIPTION
   Saves the stream specified with -User to the folder -Folder.
   In that folder the stream will be saved with the current date and time in MM-dd-yyyy-HH-mm-ss.mp4 format.
   Example: Save-Stream -User "teststreamer" -Folder "C:\Vidoes\Recordings\"
   That will create a 
.EXAMPLE
   Save-Stream -User quonic
.EXAMPLE
   Save-Stream -User quonic -Folder "C:\videos\streams\"
#>
function Save-Stream
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$false,
                   Position=0)]
        [string]
        $User = "",
        # Param1 help description
        [Parameter(Mandatory=$false,
                   Position=1)]
        [string]
        $Folder = "D:\Videos\StreamRecordings\",
        [Parameter(Mandatory=$false,
                   Position=2)]
        [string]
        $MyChannel = ""
    )

    Begin
    {
        # Setup pinfo to execute livestreamer and save the stream
        <#
        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = "livestreamer"
        $pinfo.RedirectStandardError = $true
        $pinfo.RedirectStandardOutput = $true
        $pinfo.UseShellExecute = $false
        $pinfo.Arguments = "-v -o $($Folder)\$($User)\$((Get-Date).ToString('MM-dd-yyyy-HH-mm-ss')).mp4 twitch.tv/$($User) source"
        #>

    }
    Process
    {
        if(-not (Test-Path "$($Folder)\$($User)"))
        {
            New-Item -ItemType directory -Path "$($Folder)\$($User)"
        }
        livestreamer -v -o "$($Folder)\$($User)\$((Get-Date).ToString('MM-dd-yyyy-HH-mm-ss')).mp4" "twitch.tv/$($User)" source
        <#
        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = $pinfo
        $p.Start() | Out-Host
        $p.WaitForExit()
        $stdout = $p.StandardOutput.ReadToEnd()
        $stderr = $p.StandardError.ReadToEnd()    
        #>
    }
    End
    {
        #Write-Host "stdout: $stdout"
        #Write-Host "stderr: $stderr"
        
        <#
        switch ($p.ExitCode)
        {
            0 {
                Write-Verbose "Stream Saved. Exiting..."
                }
            1 {
                Write-Verbose "stdout: $stdout"
                Write-Verbose "stderr: $stderr"
                Write-Error "Something went wrong. Exiting..." -Category OpenError -ErrorId $($p.ExitCode)
                }
            default {
                Write-Verbose "stdout: $stdout"
                Write-Verbose "stderr: $stderr"
                Write-Error "Unknown Exit Code = $($p.ExitCode). Exiting..." -Category NotImplemented -ErrorId $($p.ExitCode)
                }
        }
        #>
    }
}

function Get-TwitchStreams {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true,
                    HelpMessage='Enter the name of the Twitch account whose followed streams you wish to query.')]
        [ValidateLength(4,30)]
        [string]$TwitchUsername,
 
        [Parameter(Mandatory=$false,Position=1)]
        [string[]]$ExtraChannels
    )
 
    try {
        $channelFollowsResponse = Invoke-WebRequest -Uri "https://api.twitch.tv/kraken/users/$TwitchUsername/follows/channels?limit=100" -Method Get
    } catch {
        return $null
    }
    $channelFollowsJson = ConvertFrom-Json -InputObject $channelFollowsResponse
    $channelNames = $channelFollowsJson.follows.channel.name
    if ($ExtraChannels -ne $null) {
        $channelNames += $ExtraChannels
    }
    $channelNames | ForEach-Object {
        $channelName = $_
        $props = [ordered]@{
            "ChannelName" = $channelName;
            "Streaming" = $false;
            "DisplayName" = $null;
            "Bio" = $null;
            "Game" = $null;
            "Status" = $null;
            "Viewers" = $null;
            "Views" = $null;
            "Followers" = $null;
            "Logo" = $null;
            "Preview" = $null
        }
        $userExists = $true
        try {
            $userResponse = Invoke-WebRequest -Uri "https://api.twitch.tv/kraken/users/$channelName" -Method Get
        } catch {
            $userExists = $false
            $props["DisplayName"] = "DOES NOT EXIST"
        }
        if ($userExists) {
            $userJson = ConvertFrom-Json -InputObject $userResponse.Content
            $props["DisplayName"] = $userJson.display_name
            $props["Bio"] = $userJson.bio
            $props["Logo"] = $userJson.logo
            $streamResponse = Invoke-WebRequest -Uri "https://api.twitch.tv/kraken/streams/$channelName" -Method Get
            $streamJson = ConvertFrom-Json -InputObject $streamResponse.Content
            if ($streamJson.stream -ne $null) {
                $props["Streaming"] = $true
                $props["Game"] = $streamJson.stream.channel.game
                $props["Status"] = $streamJson.stream.channel.status
                $props["Viewers"] = $streamJson.stream.viewers
                $props["Views"] = $streamJson.stream.channel.views
                $props["Followers"] = $streamJson.stream.channel.followers
                $props["Preview"] = $streamJson.stream.preview.large
            }
        }
        $obj = New-Object -TypeName PSObject -Property $props
        Write-Output $obj
    }
}
