# This will not work on Powershell 6 as ComputerName parameter of Get-Process doesn't exist.
# This will look for open files, then atempt to kill the process.
# You can probably add something before the Kill to Close the program, wait a few seconds then kill the process.
# This doesn't check if the process is critical to the computer or not.

# Run on file server as admin/doman admin
$FilesOpen = Get-SmbOpenFile
$FilesOpen | ForEach-Object {
    $ClientComputerName = $_.ClientComputerName
    $Path = $_.Path
    Get-Process -ComputerName $ClientComputerName | ForEach-Object {
        $processVar = $_; $_.Modules | ForEach-Object {
            if ($_.FileName -eq $Path) {
                $processVar.Kill()
            }
        }
    }
}
