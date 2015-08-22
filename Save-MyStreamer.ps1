. "Save-Stream.ps1"

// Change the three below.
$Folder = "D:\Videos\StreamRecordings\"
$Streamer = ""
$Twitchusername = ""

$exittime = $false
do
{
    if((Get-TwitchStreams -TwitchUsername $Twitchusername | Where-Object {$_.ChannelName -eq $Streamer}).Streaming -eq $true)
    {
        Save-Stream
    }
    sleep -Seconds 10
    Write-Output "No stream found, waiting 10 seconds."
} until($exittime -eq $true)
