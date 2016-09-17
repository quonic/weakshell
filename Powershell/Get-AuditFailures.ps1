Param
(
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   ParameterSetName='Computer')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        $Computer = "localhost"

)
# for today
$dtime = (Get-Date).AddHours(-(Get-date).Hour).AddMinutes(-(Get-Date).Minute).AddSeconds(-(Get-Date).Second).AddMilliseconds(-(Get-Date).Millisecond)

#Get the logs for
Get-EventLog -LogName "Security" -After $dtime -ComputerName $Computer -EntryType FailureAudit | where {($_.InstanceId -eq "4663") -or ($_.InstanceId -eq "4660") -or ($_.InstanceId -eq "5145")}
