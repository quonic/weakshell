<#

Note: Customize ServerList for you enviroment.

#>


$ServerList = @(
"Vcenter1"
"Vcenter2"
)

$ServerList | ForEach-Object {
    Connect-VIServer -Server "$($_)" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
}

<#

Note: This does requre that the tags have been already created in the vcenter servers beforehand.

#>

$report = @()
$tag = ""

get-vm | foreach{
    $vm = $_
    $foundtag = $false
    $count = ""
    $count = Get-TagAssignment -Entity $vm | measure
    Write-Debug "Tag Count: $($count.Count)"
    $tag = $(Get-TagAssignment -Entity $vm).Tag.Name

    if ($count.Count -gt 0){
        #Already has a tag, do nothing.
        Get-TagAssignment -Entity $vm | foreach {
            Write-Verbose "$($vm.Name), $($_.Tag.Name)"
            $report += New-Object psobject -Property @{Name=$vm.Name;Tag=$_.Tag.Name}
        }
    }else{
        #Has no tag! Create the Tag

        Write-Verbose "$($vm.Name), $($tag)"
        
        # ------ Uncomment below to add the tag, else it will just generate a csv of what vm's have and have not any tags ------
        <#
        $myTag = Get-Tag MySillyTag
        New-TagAssignment -Tag $myTag -Entity $vm -ErrorAction Stop
        #>
        
        $tag = $(Get-TagAssignment -Entity $vm).Tag.Name
        $report += New-Object psobject -Property @{Name=$vm.Name;Tag=$tag}
    }
    Clear-Variable Tag,Tags,vm
    
}
$report | export-csv tag.csv

$m1 = get-vm | Get-TagAssignment | measure
$m2 = get-vm | measure
Write-Verbose "VM's with tags     :" + $m1.Count
Write-Verbose "VM Count :" + $m2.Count
