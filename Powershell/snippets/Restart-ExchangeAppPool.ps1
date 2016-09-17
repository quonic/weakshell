$script = {
    Import-Module WebAdministration
    $site = "Default Web Site"
    $pool = (Get-Item "IIS:\Sites\$site"| Select-Object applicationPool).applicationPool
    Restart-WebAppPool $pool
}

$servers = "EXCH1", "EXCH2", "EXCH3"

$servers | for-each {
    Invoke-Command -ScriptBlock $script -ComputerName $_
}
