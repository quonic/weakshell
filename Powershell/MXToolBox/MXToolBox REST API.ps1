$apiKey = '12345678-abc1-1a11-a123-123a12345a1a'

function Invoke-MXTBMonitor {
    Param(
        [Parameter(Mandatory)]
        [ValidateSet("mx", "a", "dns", "spf", "txt", "soa", "ptr", "blacklist", "smtp", "tcp", "http", "https", "ping", "trace")]
        [string]
        $Type,
        [Parameter(Mandatory)]
        [string[]]
        $Domain,
        [Parameter(Mandatory)]
        [string]
        $apiKey,
        [string[]]
        $Tags,
        [string]
        $Name,
        [string]
        $Command
    )
    $splat = @{
        Resource = "monitor/$($Type)/$_"
        apiKey = $apiKey
        Method = Get
    }
    $Domain | ForEach-Object {
        if($Tags){
            $splat
        }
        else
        {
            
        }
        Invoke-MXToolBoxRestMethod @splat
        
    }
}


function Invoke-MXTBLookup {
    Param(
        [ValidateSet("mx", "a", "dns", "spf", "txt", "soa", "ptr", "blacklist", "smtp", "tcp", "http", "https", "ping", "trace")]
        [string]
        $Type,
        [string[]]
        $Domain,
        [string]
        $apiKey
    )
    $Domain | ForEach-Object {
        Invoke-MXToolBoxRestMethod -Resource "lookup/$($Type)/$_" -apiKey $apiKey -Method Get
    }
}


function Invoke-MXToolBoxRestMethod
{
    Param(
        [Parameter(Position = 0, Mandatory)]
        [string]
        $Resource,
        [string]
        $apiKey,
        [ValidateSet("Get", "Post", "Delete", "Patch")]
        [string]
        $Method,
        [hashtable]
        $Options,
        [hashtable]
        $Body
    )

    # Setup Headers and cookie for splatting
    switch ($Method)
    {
        Get { $splat = PrepareGetRequest($apiKey) }
        Post { $splat = PreparePostRequest($Body,$apiKey) }
        Delete { $splat = PrepareGetRequest($apiKey) }
        Patch { $splat = PreparePatchRequest($Body,$apiKey)}
        Default { $splat = PrepareGetRequest($apiKey) }
    }

    $Query = "?"
    If ($Options)
    {
        $Options.keys | ForEach-Object {
            $Query = $Query + "$_=$($Options[$_])&"
        }
        $Query = $Query.TrimEnd("&")
    }
    else
    {
        $Query = ""
    }

    $Uri = "https://api.mxtoolbox.com/api/v1$($Resource)"

    $response = Invoke-RestMethod -Uri "$($Uri)$($Query)" @splat

    return $response.data
}

function PreparePatchRequest ($Body, $apiKey)
{
    $request = New-Object -TypeName PSCustomObject -Property @{
        Method      = "Patch"
        Headers     = @{"Accept" = "application/json", 'Authorization', $apiKey}
        Body        = $Body
        ContentType = "application/json"
    }
    return $request
}
function PreparePostRequest($Body, $apiKey)
{
    $request = New-Object -TypeName PSCustomObject -Property @{
        Method      = "Post"
        Headers     = @{"Accept" = "application/json", 'Authorization', $apiKey}
        Body        = $Body
        ContentType = "application/json"
    }
    return $request
}

function PrepareGetRequest($apiKey)
{
    $request = @{
        Method      = "Get"
        Headers     = @{"Accept" = "application/json", 'Authorization', $apiKey}
        ContentType = "application/json"
    }
    return $request
}

function PrepareDeleteRequest($apiKey)
{
    $request = New-Object -TypeName PSCustomObject -Property @{
        Method      = "Delete"
        Headers     = @{"Accept" = "application/json", 'Authorization', $apiKey}
        ContentType = "application/json"
    }
    return $request
}

