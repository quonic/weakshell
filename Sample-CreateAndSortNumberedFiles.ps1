

$working_dir = "C:\Scripts\tmp\"
#Create 1-100.txt files
1..100 | ForEach-Object{
    if(Test-Path "$working_dir\$_.txt"){
        New-Item "$($working_dir)\$($_).txt" -type file
    }
}

#Create Folders
1..10 | ForEach-Object{
    if(-not (Test-Path "$($working_dir)\$($_)0" -ErrorAction SilentlyContinue)){New-Item -Path "$working_dir\$($_)0" -ItemType Directory}
}


#Move Folders
1..100 | ForEach-Object{
    if(Test-Path "$working_dir\$_.txt"){
        switch ($_)
            {
                {($_ -ge 1) -and ($_ -le 10)} {Move-Item "$($working_dir)\$($_).txt" "$($working_dir)\10\$($_).txt" }
                {($_ -ge 11) -and ($_ -le 20)} {Move-Item "$($working_dir)\$($_).txt" "$($working_dir)\20\$($_).txt" }
                {($_ -ge 21) -and ($_ -le 30)} {Move-Item "$($working_dir)\$($_).txt" "$($working_dir)\30\$($_).txt" }
                {($_ -ge 31) -and ($_ -le 40)} {Move-Item "$($working_dir)\$($_).txt" "$($working_dir)\40\$($_).txt" }
                {($_ -ge 41) -and ($_ -le 50)} {Move-Item "$($working_dir)\$($_).txt" "$($working_dir)\50\$($_).txt" }
                {($_ -ge 51) -and ($_ -le 60)} {Move-Item "$($working_dir)\$($_).txt" "$($working_dir)\60\$($_).txt" }
                {($_ -ge 61) -and ($_ -le 70)} {Move-Item "$($working_dir)\$($_).txt" "$($working_dir)\70\$($_).txt" }
                {($_ -ge 71) -and ($_ -le 80)} {Move-Item "$($working_dir)\$($_).txt" "$($working_dir)\80\$($_).txt" }
                {($_ -ge 81) -and ($_ -le 90)} {Move-Item "$($working_dir)\$($_).txt" "$($working_dir)\90\$($_).txt" }
                {($_ -ge 91) -and ($_ -le 100)} {Move-Item "$($working_dir)\$($_).txt" "$($working_dir)\100\$($_).txt" }
                default {Write-Error "$($_) not a number?"}
            }
    }
}

