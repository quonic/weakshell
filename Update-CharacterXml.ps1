<#
.Synopsis
   Update file with EVE Online character API data
.DESCRIPTION
   Update file with EVE Online character API data. Provided that you use the same API and xml file, this will update if the xml file is 1 hour old.
   https://community.eveonline.com/support/api-key/
.EXAMPLE
   Update-CharacterXml 'example code here' 'example key here'
.EXAMPLE
   Update-CharacterXml 'example code here' 'example key here' 'c:\temp\myaltcharacter.xml'
#>
function Update-CharacterXml
{
    [CmdletBinding(PositionalBinding=$false,
                  HelpUri = 'http://www.microsoft.com/',
                  ConfirmImpact='Low')]
    Param
    (
        # Code of account API
        [Parameter(Mandatory=$true, 
                   Position=0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String]
        $Code,

        # Key of account API
        [Parameter(Mandatory=$true, 
                   Position=1)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String]
        $Key,

        # File of where to save data
        [Parameter(Mandatory=$false, 
                   Position=2)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String]
        $File = 'Characters.xml'
    )

    Process
    {
        $uri = 'https://api.eveonline.com/account/Characters.xml.aspx'

        if (test-path $File){
            [xml]$xml = (Get-Content "$File") 
        }else{
            Invoke-RestMethod -Method Get $uri$Key$Code -OutFile $File
            [xml]$xml = (Get-Content "$File")
        }

        $currenttime = (Get-Date).ToShortTimeString()
        $cacheduntilinxml = Get-Date $xml.eveapi.cachedUntil
        $cacheduntil = $cacheduntilinxml.AddHours(1).ToShortTimeString()

        if($currenttime -gt $cacheduntil){
            Invoke-RestMethod -Method Get $uri$Key$Code -OutFile $File
            Write-Verbose "Cache has expired. File $File updated."
        }else{
            Write-Verbose "Cache has not expired."
        }
    }
}
