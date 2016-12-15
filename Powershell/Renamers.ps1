# TODO: create an extention cleaner and renamer


<#
.Synopsis
   Removes the specified text from the start of a file name
.DESCRIPTION
   Long description
.EXAMPLE
   TrimLeft-Files "Begining-" ".\"
#>
function TrimLeft-Files
{
    [CmdletBinding()]
    [Alias()]
    Param
    (
        # Text to remove
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$false,
                   Position=0)]
                   [string]
        $Text,

        # Param2 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$false,
                   Position=1)]
        [string]
        $Folder
    )

    Begin
    {
        $items = Get-ChildItem -Path $Folder
    }
    Process
    {

        $Text = "Remove This"

        $items | ForEach-Object{
            if($_.BaseName.Contains($Text)){
                $name = $_.Name
                $nameLen = $name.Length - $Text.Length
                Rename-Item $name $name.Substring($Text.Length,$nameLen)
            }
        }
    }
    End
    {
    }
}
