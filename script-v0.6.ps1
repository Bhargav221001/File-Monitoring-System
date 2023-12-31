
Import-Module -Name "C:\Projects\File_Integrity_monitor\mail.ps1"
Add-Type -AssemblyName System.Windows.Forms

# # takes user name and password(Encrypted)
# $Creds = Get-Credential 
# # creates and stores the username and password(Encrypted) int he emailcred.xml file 
# $creds | Export-Clixml -Path "C:\Projects\File_Integrity_monitor\Emailcred.xml" 

$emailCredPath = "C:\Projects\File_Integrity_monitor\Emailcred.xml"
$emailCred = Import-Clixml -Path $emailCredPath
$emailServer = "smtp-mail.outlook.com"
$emailPort = "587"


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
            Write-Error $_.Exception.Message;
        }
}

function Verify-BaseLine{
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)] $baselineFilePath,
        [Parameter()] $emailTo
    )
    try {
        do{
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
                    if($emailTo){
                        Send-MailKitMessage -To $emailTo -From $emailCred.username -Subject "File Monitoring System, Your file has been modified!!" -Body " Something has been changed in $($file.path)" -SMTPServer $emailServer -Port $emailPort -Credential $emailCred 
                    }
                }
            }
            else{
                Write-Output "$($file.path) is not found!!"
                Send-MailKitMessage -To $emailTo -From $emailCred.username -Subject "File Monitoring System, Your file has been Deleted!!" -Body " The file in $($file.path) has been deleted" -SMTPServer $emailServer -Port $emailPort -Credential $emailCred 
            }
        }
        Start-Sleep -Seconds 10
    }
    while ($true){}
    }
    catch {
        Write-Error $_.Exception.Message;
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
        if($baselineFilePath.Substring($baselineFilePath.length-4,4) -ne ".csv"){
            Write-Error -Message "$baselineFilePath BaseLine file should be a .csv file" -ErrorAction Stop
        }
        "path,hash" | Out-File -FilePath $baselineFilePath -Force
    }
    catch {
        Write-Error $_.Exception.Message
    }
}
$baselineFilePath = ""
$targetFilePath ="C:\Projects\File_Integrity_monitor\test1.txt"



do{
    Write-Host "Select any of the following options to start or type q to quit" -ForegroundColor Blue
    Write-Host "1. Set Baseline path, current baseline $($baselineFilePath)" -ForegroundColor green
    Write-Host "2. Select File to moniter" -ForegroundColor green  #Add path to baseline
    Write-Host "3. Check files against baseline" -ForegroundColor green
    Write-Host "4. Check files against baseline with email" -ForegroundColor green
    Write-Host "5. Create a new baseline" -ForegroundColor green
    
    $entry = Read-Host -Prompt "Enter your selection" 

    switch ($entry) {
        "1"{
            $inputFilePick = New-Object System.Windows.Forms.OpenFileDialog
            $inputFilePick.Filter = "CSV (*.csv) | *.csv"
            $inputFilePick.ShowDialog()
            $baselineFilePath = $inputFilePick.FileName
            if(Test-Path -Path $baselineFilePath){
                if($baselineFilePath.Substring($baselineFilePath.length-4,4) -eq ".csv"){
                }
                else{
                    Write-Host "Invalid file, needs to be a.csv file" -ForegroundColor Red
                }
            }else{
                $baselineFilePath = ""
                Write-Host "Invalid file path" -ForegroundColor Red
            }
        }
        "2"{
            $inputFilePick = New-Object System.Windows.Forms.OpenFileDialog
            $inputFilePick.ShowDialog()
            $targetFilePath = $inputFilePick.FileName
            Add-fileToBaseline -baselineFilePath $baselineFilePath -targetFilePath $targetFilePath
        }
        "3"{
            Verify-BaseLine -baselineFilePath $baselineFilePath
        }
        "4"{
            $email = Read-Host "Enter your Email"
            Verify-BaseLine -baselineFilePath $baselineFilePath -emailTo $email
        }  
        "5"{
            $inputFilePick = New-Object System.Windows.Forms.SaveFileDialog
            $inputFilePick.Filter = "CSV (*.csv) | *.csv"
            $inputFilePick.ShowDialog()
            $newBaselineFilePath = $inputFilePick.FileName
            CreateBaseLine -baselineFilePath $newBaselineFilePath
        }       
        "q"{}
        "quit"{}
        Default{
            Write-Host "Invalid Entry !!!" -ForegroundColor Red
        }
    }
}
while($entry -notin @('q','quit'))
# CreateBaseLine -baselineFilePath $baselineFilePath

# adding file to the new baseline file
# Add-fileToBaseline -baselineFilePath $baselineFilePath -targetFilePath "C:\Projects\File_Integrity_monitor\test2.txt"

# verifying wether the  file has been changed

# verify without email
# Verify-BaseLine -baselineFilePath $baselineFilePath

# # verify with email
# Verify-BaseLine -baselineFilePath $baselineFilePath -emailTo "aishanyapattanaik1112@gmail.com"
