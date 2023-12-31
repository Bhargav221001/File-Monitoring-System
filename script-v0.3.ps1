# creating function for adding values to baseline

function Add-fileToBaseline {
    
        [CmdletBinding()]
        param (
            [Parameter(Mandatory)]$baselineFilePath,
            [Parameter(Mandatory)]$targetFilePath
        )
        try {
            if((Test-Path -Path $baselineFilePath) -eq $false){
                Write-Error -Message "$baselineFilePath does not exists!!" -ErrorAction Stop
            }
            if((Test-Path -Path $targetFilePath) -eq $false){
                Write-Error -Message "$targetFilePath does not exists!!" -ErrorAction Stop
            }

            $currntBaseLine = Import-Csv -Path $baselineFilePath -Delimiter ","
            if($targetFilePath -in $currntBaseLine.path){
                Write-Output "File path already detected already in baseline file"
                do{
                    $overwrite  = Read-Host -Prompt "Path already exists in the baseline path would you like to overwrite [Y/N]:"
                    if($overwrite -in @("Y","y")){
                        Write-Output "Path will be overwritten !!"
                        #code for overwriting
                        $currntBaseLine | Where-Object path -ne $targetFilePath | Export-Csv -Path $baselineFilePath -Delimiter "," -NoTypeInformation                    
                    
                        # adding the updated hash
                        $hash = Get-FileHash -Path $targetFilePath

                        "$($targetFilePath),$($hash.hash)" | Out-File -FilePath $baselineFilePath -Append
                        Write-Output "Entry Successfully added into baseline"
                    }
                    elseif($overwrite -in @("N","n")){
                        Write-Output "The File will not be overwritten"
                    }
                    else{
                        Write-Output "Invalid Entry !!!!!"
                    }
                }while($overwrite -notin @("Y","N","y","n"))
            }
            else{
                # by default uses SHA-256
                # adding file to baseline.csv
                $hash = Get-FileHash -Path $targetFilePath

                "$($targetFilePath),$($hash.hash)" | Out-File -FilePath $baselineFilePath -Append
                Write-Output "Entry Successfully added into baseline"
            }
            $currntBaseLine = Import-Csv -Path $baselineFilePath -Delimiter ","
            $currntBaseLine  | Export-Csv -Path $baselineFilePath -Delimiter "," -NoTypeInformation                    
 
        }
        catch {
            return $_.Exception.Message;
        }
}

function Verify-BaseLine{
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)] $baselineFilePath
    )
    try {
        if((Test-Path -Path $baselineFilePath) -eq $false){
            Write-Error -Message "$baselineFilePath does not exists!!" -ErrorAction Stop
        }
        ## for monitoring files:
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
    }
    catch {
        return $_.Exception.Message;
    }
}

function CreateBaseLine{
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)] $baselineFilePath
    )
    try {
        if((Test-Path -Path $baselineFilePath)){
            Write-Error -Message "$baselineFilePath Already Exists with this name!!!" -ErrorAction Stop
        }
        "path,hash" | Out-File -FilePath $baselineFilePath -Force
    }
    catch {
        return $_.Exception.Message
    }
}
$baselineFilePath = "C:\Projects\File_Integrity_monitor\baseline.csv"
$targetFilePath ="C:\Projects\File_Integrity_monitor\test1.txt"


# CreateBaseLine -baselineFilePath $baselineFilePath

# adding file to the new baseline file
Add-fileToBaseline -baselineFilePath $baselineFilePath -targetFilePath "C:\Projects\File_Integrity_monitor\test2.txt"

# verifying wether the  file has been changed
# Verify-BaseLine -baselineFilePath $baselineFilePath
