# One way to write self modifing PowerShell code


#<Config%
#%Config>
$WaitTillEndTag = $false
$output = Get-Content -Path $PSCommandPath | ForEach-Object{
    if($_ -like "#<Config%"){
        $WaitTillEndTag = $true
        Write-Output '#<Config%'
        Write-Output '$myVariable = "My config data"'
        Get-Date | Write-Output
    }elseif($_ -like "#%Config>"){
        Write-Output '#%Config>'
    }else{
        Write-Output "$_"
    }
}
Write-Output $output
$output | Out-File -FilePath $PSCommandPath
