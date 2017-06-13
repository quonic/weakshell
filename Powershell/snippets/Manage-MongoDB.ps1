
Param([switch]$Install, [switch]$Remove)

# Check for Mdbc and install if older or not installed
$MdbcInstalled = Get-Module Mdbc* -ListAvailable
if($MdbcInstalled){
    $PSGallaryMdbc = Find-Module -Name Mdbc
    if($MdbcInstalled.Version -eq $PSGallaryMdbc.Version){
        Write-Output "Lastest Mdbc Installed"
    }else{
        Write-Output "Updating Mdbc for CurrentUser"
        Write-Output "Install-Module -Name Mdbc -Scope CurrentUser"
        Install-Module -Name Mdbc -Scope CurrentUser
    }
}else{
    $MdbcModulesList = Get-Module Mdbc* -ListAvailable
    $MdbcModulesToRemove = @()
    if($MdbcModulesList){
        Write-Output "Installing Mdbc for CurrentUser"
        Write-Output "Install-Module -Name Mdbc -Scope CurrentUser"
        Install-Module -Name Mdbc -Scope CurrentUser
    }
}

$mongoDbPath = "$PSScriptRoot\MongoDB"
$mongoDbConfigPath = "$mongoDbPath\mongod.cfg"
$url = "http://downloads.mongodb.org/win32/mongodb-win32-x86_64-2008plus-ssl-v3.4-latest.zip" 
$zipFile = "$mongoDbPath\mongo.zip" 
$unzippedFolderContent ="$mongoDbPath\mongodb-win32-x86_64-2008plus-ssl-v3.4-latest"

if($Install){
    if ((Test-Path -path $mongoDbPath) -eq $false)
    {
        Write-Host "Setting up directories..."
        $temp = mkdir $mongoDbPath 
        $temp = mkdir "$mongoDbPath\log" 
        $temp = mkdir "$mongoDbPath\data" 
        $temp = mkdir "$mongoDbPath\data\db"

        Write-Host "Setting up mongod.cfg..."
        [System.IO.File]::AppendAllText("$mongoDbConfigPath", "dbpath=$mongoDbPath\data\db`r`n")
        [System.IO.File]::AppendAllText("$mongoDbConfigPath", "logpath=$mongoDbPath\log\mongo.log`r`n")
        [System.IO.File]::AppendAllText("$mongoDbConfigPath", "smallfiles=true`r`n")

        Write-Host "Downloading MongoDB..."
        $webClient = New-Object System.Net.WebClient 
        $webClient.DownloadFile($url,$zipFile)

        Write-Host "Unblock zip file..."
        Get-ChildItem -Path $mongoDbPath -Recurse | Unblock-File

        Write-Host "Unzipping Mongo files..."
        $shellApp = New-Object -com shell.application 
        $destination = $shellApp.namespace($mongoDbPath) 
        $destination.Copyhere($shellApp.namespace($zipFile).items())
        
        Copy-Item "$unzippedFolderContent\*" $mongoDbPath -recurse

        Write-Host "Cleaning up..."
        Remove-Item $unzippedFolderContent -recurse -force 
        Remove-Item $zipFile -recurse -force

        Write-Host "Installing Mongod as a service..."
        & $mongoDBPath\bin\mongod.exe --config $mongoDbConfigPath --install
        
        Write-Host "Starting Mongod..."
        & net start mongodb
        
    }
    else {
        Write-Host "MongoDB already installed."
        Write-Host "Starting Mongod..."
        & net start mongodb
    }
}
if($Remove){
    & $mongoDBPath\bin\mongod.exe --config $mongoDbConfigPath --remove
    Remove-Item -Path $mongoDbPath -Recurse -Force
    Write-Host "MongoDB Removed."
}
