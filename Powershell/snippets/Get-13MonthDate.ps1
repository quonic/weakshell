# This will output the date in a 13 month type of calandar
# The nice thing about this is that the code doesn't have to care about leap years

$StartDate = Get-Date -Day 1 -Month 1 -Year $(Get-Date).Year
$EndDate = Get-Date
$Days = $(New-TimeSpan –Start $StartDate –End $EndDate).Days


$i = $Days
$done = $false
$month = 1
$day = 1
Do{
    if($i -gt 28){
        $i = $i - 28
        $month++
    }elseif($i -gt 0){
        $i = $i - 1
        $day++
    }else{
        $done = $true
    }
        
}while(-not $done)

$dayofweeknumber = $day
Write-Output $dayofweeknumber
if($day -gt 7){
    if($day -gt 14){
        if($day -gt 21){
            $dayofweeknumber = $dayofweeknumber - 7
        }
        $dayofweeknumber = $dayofweeknumber - 7
    }
    $dayofweeknumber = $dayofweeknumber - 7
}

if($dayofweeknumber -gt 28 -and $month -eq 13){
    $month = 14
    $dayofweeknumber = $dayofweeknumber - 28
    $newyear = $true
}

switch ($dayofweeknumber)
{
    1 {$dayofweek = "Sunday"}
    2 {$dayofweek = "Monday"}
    3 {$dayofweek = "Tuesday"}
    4 {$dayofweek = "Wednesday"}
    5 {$dayofweek = "Thurday"}
    6 {$dayofweek = "Friday"}
    7 {$dayofweek = "Saturday"}
    default {Write-Output "ERROR!"}
}
if($newyear){
    Write-Output "Month: $month, Day: $day, New Years!"
}else{
    Write-Output "Month: $month, Day: $day, Day of week:$dayofweek"
}
