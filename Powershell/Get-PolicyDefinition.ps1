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
    begin {}
    process {
        $PolicyDefPath = Join-Path -Path $env:SystemRoot -ChildPath "PolicyDefinitions" | Resolve-Path | Get-Item -ErrorAction Stop
        $LangPath = Join-Path -Path $PolicyDefPath -ChildPath $(Get-WinSystemLocale).Name | Resolve-Path | Get-Item -ErrorAction Stop

        $AdmxFiles = Get-ChildItem -Path $PolicyDefPath -Filter "*.admx" -ErrorAction Stop
        $LanguageFiles = Get-ChildItem -Path $LangPath -Filter "*.adml" -ErrorAction Stop

        # Import xml data from .admx files andget only the policies
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

        # Loop through each policy
        foreach ($Policy in $Policies) {
            if (
                $(
                    $PSBoundParameters.ContainsKey('Name') -and
                    $(
                        $Policy.Name -like $Name -or
                        $Policy.Name -in $Name
                    )
                ) -or
                $(
                    $PSBoundParameters.ContainsKey('Class') -and
                    $(
                        $Policy.class -like $Class -or
                        $Policy.class -in $Class
                    )
                ) -or
                $(
                    -not $PSBoundParameters.ContainsKey('Name') -and
                    -not $PSBoundParameters.ContainsKey('Class')
                )
            ) {
                [System.Collections.Generic.List[string]]$defaultDisplaySet = 'Name', 'Class', 'DisplayName', 'Key'
                $out = [PSCustomObject]@{
                    Name        = $Policy.Name
                    Class       = $Policy.class
                    DisplayName = $($lang | Where-Object { $_.id -like $($Policy.displayName -replace "\`$\(string\." -replace "\)") }).text
                    ExplainText = $($lang | Where-Object { $_.id -like $($Policy.explainText -replace "\`$\(string\." -replace "\)") }).text
                    Key         = $Policy.key
                }

                if ($Policy.elements) {
                    $out | Add-Member -Name Elements -Value $Policy.elements -MemberType NoteProperty
                    $defaultDisplaySet.Add('Elements')
                }
                if ($Policy.policyDefinitions.policies.policy.enabledValue) {
                    $out | Add-Member -Name EnabledValue -Value $Policy.policyDefinitions.policies.policy.enabledValue -MemberType NoteProperty
                    $defaultDisplaySet.Add('EnabledValue')
                }
                if ($Policy.policyDefinitions.policies.policy.disabledValue) {
                    $out | Add-Member -Name DisabledValue -Value $Policy.policyDefinitions.policies.policy.disabledValue -MemberType NoteProperty
                    $defaultDisplaySet.Add('DisabledValue')
                }
                if (-not $out.Elements -and -not $out.EnabledValue) {
                    $out | Add-Member -Name IsBoolean -Value $true -MemberType NoteProperty
                    $defaultDisplaySet.Add('IsBoolean')
                }
    
                $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet', [string[]]$defaultDisplaySet)
                $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
                $out | Add-Member MemberSet PSStandardMembers $PSStandardMembers
                $out
            }
        }
    }
    end {}
}
