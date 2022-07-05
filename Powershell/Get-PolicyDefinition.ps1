function Get-PolicyDefinition {
    [CmdletBinding(
        ConfirmImpact = 'None',
        RemotingCapability = [System.Management.Automation.RemotingCapability]::PowerShell
    )]
    [OutputType([PSObject[]])]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]
        $Name,
        [Parameter(Mandatory = $false)]
        [string[]]
        $Class
    )
    begin {
        function ConvertFrom-XML {
            [CmdletBinding()]
            param
            (
                [Parameter(Mandatory = $true, ValueFromPipeline)]
                [System.Xml.XmlNode]$node, #we are working through the nodes
                [string]$Prefix = '', #do we indicate an attribute with a prefix?
                $ShowDocElement = $false #Do we show the document element? 
            )
            # Source: https://www.red-gate.com/simple-talk/blogs/convert-from-xml/
            process {
                #if option set, we skip the Document element
                if ($node.DocumentElement -and !($ShowDocElement)) 
                { $node = $node.DocumentElement }
                $oHash = [ordered] @{ } # start with an ordered hashtable.
                #The order of elements is always significant regardless of what they are
                write-verbose "calling with $($node.LocalName)"
                if ($null -ne $node.Attributes) {
                    #if there are elements
                    # record all the attributes first in the ordered hash
                    $node.Attributes | ForEach-Object {
                        $oHash.$($Prefix + $_.FirstChild.parentNode.LocalName) = $_.FirstChild.value
                    }
                }
                # check to see if there is a pseudo-array. (more than one
                # child-node with the same name that must be handled as an array)
                $node.ChildNodes | #we just group the names and create an empty
                #array for each
                Group-Object -Property LocalName | Where-Object { $_.count -gt 1 } | Select-Object Name |
                ForEach-Object {
                    write-verbose "pseudo-Array $($_.Name)"
                    $oHash.($_.Name) = @() <# create an empty array for each one#>
                };
                foreach ($child in $node.ChildNodes) {
                    #now we look at each node in turn.
                    write-verbose "processing the '$($child.LocalName)'"
                    $childName = $child.LocalName
                    if ($child -is [system.xml.xmltext]) {
                        # if it is simple XML text 
                        write-verbose "simple xml $childname";
                        $oHash.$childname += $child.InnerText
                    }
                    # if it has a #text child we may need to cope with attributes
                    elseif ($child.FirstChild.Name -eq '#text' -and $child.ChildNodes.Count -eq 1) {
                        write-verbose "text";
                        if ($null -ne $child.Attributes) {
                            #hah, an attribute
                            <#we need to record the text with the #text label and preserve all
					the attributes #>
                            $aHash = [ordered]@{ };
                            $child.Attributes | ForEach-Object {
                                $aHash.$($_.FirstChild.parentNode.LocalName) = $_.FirstChild.value
                            }
                            #now we add the text with an explicit name
                            $aHash.'#text' += $child.'#text'
                            $oHash.$childname += $aHash
                        }
                        else {
                            #phew, just a simple text attribute. 
                            $oHash.$childname += $child.FirstChild.InnerText
                        }
                    }
                    elseif ($null -ne $child.'#cdata-section') {
                        # if it is a data section, a block of text that isnt parsed by the parser,
                        # but is otherwise recognized as markup
                        write-verbose "cdata section";
                        $oHash.$childname = $child.'#cdata-section'
                    }
                    elseif ($child.ChildNodes.Count -gt 1 -and 
                        ($child | Get-Member -MemberType Property).Count -eq 1) {
                        $oHash.$childname = @()
                        foreach ($grandchild in $child.ChildNodes) {
                            $oHash.$childname += (ConvertFrom-XML $grandchild)
                        }
                    }
                    else {
                        # create an array as a value  to the hashtable element
                        if ($oHash.$childname -is [System.Management.Automation.PSParameterizedProperty]) {
                            $oHash.$childname = $oHash.$childname, (ConvertFrom-XML $child)
                        }
                        else {
                            $oHash.$childname += (ConvertFrom-XML $child)
                        }
                    }
                }
                $oHash
            }
        }
    }
    process {
        $PolicyDefPath = Join-Path -Path $env:SystemRoot -ChildPath "PolicyDefinitions" | Resolve-Path | Get-Item -ErrorAction Stop
        $LangPath = Join-Path -Path $PolicyDefPath -ChildPath $(Get-WinSystemLocale).Name | Resolve-Path | Get-Item -ErrorAction Stop

        $AdmxFiles = Get-ChildItem -Path $PolicyDefPath -Filter "*.admx" -ErrorAction Stop
        $LanguageFiles = Get-ChildItem -Path $LangPath -Filter "*.adml" -ErrorAction Stop

        # Import xml data from .admx files and get only the policies
        $Policies = $(
            $AdmxFiles | ForEach-Object {
                [xml]$(Get-Content -Path $_ -Raw -ErrorAction Stop)
            }
        ).policyDefinitions.policies.policy

        # Get our id and text data from the .amdl files
        $lang = $LanguageFiles | ForEach-Object {
            $l = $([xml]$(Get-Content -Path $_ -Raw -ErrorAction Stop)).policyDefinitionResources.resources.stringTable.string
            for ($i = 0; $i -lt $l.Count; $i++) {
                [PSCustomObject]@{
                    id   = $l[$i].id
                    text = $l[$i]."#text"
                }
            }
        }
        if ($PSBoundParameters.ContainsKey('Debug')) {
            $DebugPreference = 'Stop'
        }
        # Loop through each policy
        foreach ($Policy in $Policies) {
            $htPolicy = ConvertFrom-XML $Policy
            if (
                $(
                    $PSBoundParameters.ContainsKey('Name') -and
                    $PSBoundParameters.ContainsKey('Class') -and
                    $(
                        $(
                            $htPolicy.Name -like $Name -or
                            $htPolicy.Name -in $Name
                        ) -and
                        $(
                            $htPolicy.class -like $Class -or
                            $htPolicy.class -in $Class
                        )
                    )
                ) -or
                $(
                    $PSBoundParameters.ContainsKey('Name') -and
                    -not $PSBoundParameters.ContainsKey('Class') -and
                    $(
                        $htPolicy.Name -like $Name -or
                        $htPolicy.Name -in $Name
                    )
                ) -or
                $(
                    $PSBoundParameters.ContainsKey('Class') -and
                    -not $PSBoundParameters.ContainsKey('Name') -and
                    $(
                        $htPolicy.class -like $Class -or
                        $htPolicy.class -in $Class
                    )
                ) -or
                $(
                    -not $PSBoundParameters.ContainsKey('Name') -and
                    -not $PSBoundParameters.ContainsKey('Class')
                )
            ) {
                $htPolicy.displayName = $($lang | Where-Object { $_.id -like $($htPolicy.displayName -replace "\`$\(string\." -replace "\)") }).text
                $htPolicy.explainText = $($lang | Where-Object { $_.id -like $($htPolicy.explainText -replace "\`$\(string\." -replace "\)") }).text
                $htPolicy
            }
        }
    }
    end {}
}
