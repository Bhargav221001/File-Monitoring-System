$baselineFilePath = "C:\Projects\File_Integrity_monitor\baseline.csv"
$fileToMonitorPath ="C:\Projects\File_Integrity_monitor\test1.txt"

# by default uses SHA-256
# adding file to baseline.csv
$hash = Get-FileHash -Path $fileToMonitorPath

"$($fileToMonitorPath),$($hash.hash)" | Out-File -FilePath $baselineFilePath -Append

# for monitoring files:

$baselineFiles = Import-Csv -Path $baselineFilePath -Delimiter ","

foreach($file in $baselineFiles){
   
    if(Test-Path -Path $file.path){
        $currenthash = Get-FileHash -Path $file.path
        if($currenthash.Hash -eq $file.hash){
            Write-Output "$($file.path) file hasen't been updated"
        }
        else{
            Write-Output "$($file.path) Some thing is changed!!"
        }
    }
    else{
        Write-Output "$($file.path) is not found!!"
    }
}