<#
.SYNOPSIS
    Script to compare given values of user account with the actual values as shown with the net user cmdlet.
#>



param (
    <#
    Non mandatory parameters
    #>
    [Parameter(HelpMessage="Enter one or more account names separated by commas.")] <# HelpMessage has no effect on non mandatory parameters #>
    [array] $AccountName=@(),
    [Parameter(HelpMessage="Enter single word without quotes or a string with quotes.")]
    [string] $logFileNamePrefix="" #Default value is empty - prefix to the log file
)

<#
Initialize the logfile name and have option to retrive errorfile path , errorfile name, successfile path and successfile name.
Also verify if logFileNamePrefix is available or not.
Handle other errors.
#>
function LogFileName {
    [cmdletbinding()]
    param (
        [switch] $errorFilePath,
        [switch] $successFilePath,
        [switch] $successFileName,
        [switch] $errorFileName
    )
    try {
        Write-Verbose "LogFileName function started" -Verbose
        <#
        currentFolderPath - Name of the path where the executable reside relative to path of the console.
        #>
        $currentFolderPath = Split-Path $script:MyInvocation.MyCommand.Path
        $currentFolderPath += '\'
        <#
        compname - Current local computer name where the script is executed.
        #>
        $compName = $env:COMPUTERNAME

        if ($errorFilePath) {
            if ((-not $logFileNamePrefix)) {
                $outputFilename = "$($compName)_ERROR.txt"
                $logFilePath = $currentFolderPath + $outputFilename
                return $logFilePath
            }
            elseif (($logFileNamePrefix)) {
                $outputFilename = "$($logFileNamePrefix)_$($compName)_ERROR.txt"
                $logFilePath = $currentFolderPath + $outputFilename
                return $logFilePath
            }
            else {
                $outputFilename = "ERROR.txt"
                $logFilePath = $currentFolderPath + $outputFilename
                return $logFilePath
            }
        }
        elseif ($successFilePath) {
            if ((-not $logFileNamePrefix)) {
                $outputFilename = "$($compName)_SUCCESS.txt"
                $logFilePath = $currentFolderPath + $outputFilename
                return $logFilePath
            }
            elseif (($logFileNamePrefix)) {
                $outputFilename = "$($logFileNamePrefix)_$($compName)_SUCCESS.txt"
                $logFilePath = $currentFolderPath + $outputFilename
                return $logFilePath
            }
            else {
                $outputFilename = "SUCCESS.txt"
                $logFilePath = $currentFolderPath + $outputFilename
                return $logFilePath
            }
        }
        elseif ($errorFileName) {
            if ((-not $logFileNamePrefix)) {
                $outputFilename = "$($compName)_ERROR.txt"
                $logFilePath = $currentFolderPath + $outputFilename
                return $logFilePath
            }
            elseif (($logFileNamePrefix)) {
                $outputFilename = "$($logFileNamePrefix)_$($compName)_ERROR.txt"
                $logFilePath = $currentFolderPath + $outputFilename
                return $logFilePath
            }
            else {
                $outputFilename = "ERROR.txt"
                return $outputFilename
            }
        }
        elseif ($successFileName) {
            if ((-not $logFileNamePrefix)) {
                $outputFilename = "$($compName)_SUCCESS.txt"
                $logFilePath = $currentFolderPath + $outputFilename
                return $logFilePath
            }
            elseif (($logFileNamePrefix)) {
                $outputFilename = "$($logFileNamePrefix)_$($compName)_SUCCESS.txt"
                $logFilePath = $currentFolderPath + $outputFilename
                return $logFilePath
            }
            else {
                $outputFilename = "SUCCESS.txt"
                return $outputFilename
            }
        }
        elseif ((-not $logFileNamePrefix)) {
                $outputFilename = "$($compName).txt"
                $logFilePath = $currentFolderPath + $outputFilename
                return $logFilePath
        }
        elseif (($logFileNamePrefix)) {
            $outputFilename = "$($logFileNamePrefix)_$($compName).txt"
            $logFilePath = $currentFolderPath + $outputFilename
            return $logFilePath
        }
        else {
            $logFilePath = ""
            return $logFilePath
        }
    }
    catch {
        <#
        Exeption Handling - Catch block for the function LogFileName
        No need to check for existing filepath as this function is executed at the top.
        #>
        $logFilePath = LogFileName -errorFilePath
        Submit-Log -text "New LogFilePath : $($logFilePath)"
        Submit-Log -text "Error while Initializing logfilename" -errorRecord $_
        exit
    }
}

<#
Log function to output to verbose stream as well as log into file
#>
function Submit-Log {
    [cmdletbinding()]
    param (
        [string]$text,
        $errorRecord
    )

    # Prepend time with text using get-date and .tostring method
    $Entry = (Get-Date).ToString( 'M/d/yyyy HH:mm:ss - ' ) + $text

    #  Write entry to log file
    $Entry | Out-File -FilePath $logFilePath -Encoding UTF8 -Append

    #  Write entry to screen
    Write-Verbose -Message $Entry -Verbose

    #  If error record included
    #   Recurse to capture exception details
    If ( $errorRecord -is [System.Management.Automation.ErrorRecord] )
    {
        Submit-Log -Text "Exception.Message [$($errorRecord.Exception.Message)]"
        Submit-Log -Text "Exception.GetType() [$($errorRecord.Exception.GetType())]"
        Submit-Log -Text "Exception.InnerException.Message [$($errorRecord.Exception.InnerException.Message)]"
    }
}

<#
The purpose of this function is to validate the parameters.
Here we check if the AccountName array is empty or not.
#>
function ParameterValidation {
    [cmdletbinding()]
    param (
       [array] $AccountName
    )
    Submit-Log -text "ParameterValidation Function started"
    try {
        if (-Not $AccountName) {
            if ($logFilePath) {
                $fileName = logFileName  -errorFileName
                Rename-Item -Path "$($logFilePath)" -NewName "$($fileName)" -Force
            }
            $logFilePath = LogFileName -errorFilePath
            Submit-Log -text "New LogFilePath : $($logFilePath)"
            Submit-Log -text "Account Name Array is Empty"
            exit
        }
        Submit-Log -text "ParameterValidation Function ended"
    }
    catch {
        if ($logFilePath) {
            $fileName = logFileName  -errorFileName
            Rename-Item -Path "$($logFilePath)" -NewName "$($fileName)" -Force
        }
        <#
        Change the logFilePath even if the logFilePath is empty or not and hence no else statement.
        #>
        $logFilePath = LogFileName -errorFilePath
        Submit-Log -text "New LogFilePath : $($logFilePath)"
        Submit-Log -text "Error while excecuting within ParameterValidation Function" -errorRecord $_
        exit
    }
}

<#
Set all non terminating errors to terminating.
#>
$ErrorActionPreference = 'Stop'

<#
netUserProperty_with_expectedvalue is a hashtable to store the netuser properties that need to be verified as the key and desired values as the values in the hashtable.
#>
$netUserProperty_with_expectedvalue = @{'Account active' = 'Yes'
                            'Password expires' = 'Never'
                            'User may change password' = 'Yes'
}

<#
Flag to determine if the netUserProperty_with_expectedvalue values match with the actual netuser values. Used in the foreach-object while looping through the netUserProperty_with_expectedvalue hash table.
#>
$successFlag = $true

Write-Verbose "File Name Prefix: $($logFileNamePrefix)" -Verbose
$logFilePath = LogFileName
Write-Verbose "Prevalidated Log File Path: $($logFilePath)" -verbose

if (-not $logFilePath) {
    <#
    No need to check for existing filepath as logFileName function is executed at the top.
    #>
    $logFilePath = LogFileName -errorFilePath
    Submit-Log -text "Log File Path is empty"
    Submit-Log -text "New LogFilePath : $($logFilePath)"
    exit
}

Submit-Log -text "`n`n Start of program - LogFilePath initialized"
Submit-Log -text "New LogFilePath : $($logFilePath)"

<#
Calling parameterValidation function
#>
try {
    ParameterValidation $AccountName
    Submit-Log -text "AccountName array Not empty"
}
catch {
    if ($logFilePath) {
        $fileName = logFileName  -errorFileName
        Rename-Item -Path "$($logFilePath)" -NewName "$($fileName)" -Force
    }
    <#
    Change the logFilePath even if the logFilePath is empty or not and hence no else statement.
    #>
    $logFilePath = LogFileName -errorFilePath
    Submit-Log -text "New LogFilePath : $($logFilePath)"
    Submit-Log -text "Error while calling ParameterValidation Function" -errorRecord $_
    exit
}


$AccountName | ForEach-Object{
    <#
    Output Array with the resulting values from netuser and status {EXPECTED,NOT EXPECTED}
    #>
    $netUserProperty_with_currentvalue_array = @()
    <#
    Net user execution with respective account names.
    #>
    try {
        Submit-Log -text "Executing net user"
        $netuserobject = net user $_ 2>&1
    }
    catch {
        if ($logFilePath) {
            $fileName = logFileName  -errorFileName
            Rename-Item -Path "$($logFilePath)" -NewName "$($fileName)" -Force
        }
        <#
        Change the logFilePath even if the logFilePath is empty or not and hence no else statement.
        #>
        $logFilePath = LogFileName -errorFilePath
        Submit-Log -text "New LogFilePath : $($logFilePath)"
        Submit-Log -text "Error while excecuting net user. Possibly wrong username" -errorRecord $_
        exit
    }
    Submit-Log -text "------------------------  OUTPUT  $(([array]::indexof($AccountName,$_))+1) ------------------------------------"
    Submit-Log -text "Account Name : $($_)"
    Submit-Log -text "----------------------------"
    <#
    We iterate through the hashtable and find the key in the netuserobject and futher find the expected value.
    This is then logged in to the verbose stream and log file.
    #>
    foreach ($key in $netUserProperty_with_expectedvalue.Keys) {
        $netUserProperty_with_currentvalue = [PSCustomObject]@{}
        try {
            if ( $netuserobject | findstr /c:"$($key)") {
                if ($netuserobject | findstr /c:"$($key)" | findstr /c:"$($netUserProperty_with_expectedvalue.$key)") {
                    $netUserProperty_with_currentvalue = [PSCustomObject]@{
                        "Property" = $key
                        "Value" = $netUserProperty_with_expectedvalue.$key
                        "Expected Value" = $netUserProperty_with_expectedvalue.$key
                    }
                    $netUserProperty_with_currentvalue_array += $netUserProperty_with_currentvalue
                }
                else {
                    $netuserobject_indexvalue = $netuserobject | findstr /c:"$($key)"
                    $netuserobject_indexvalue = $netuserobject_indexvalue -split "\s\s"
                    $netUserProperty_with_currentvalue = [PSCustomObject]@{
                        "Property" = $key
                        "Value" = $netuserobject_indexvalue[-1]
                        "Expected Value" = $netUserProperty_with_expectedvalue.$key
                    }
                    $netUserProperty_with_currentvalue_array += $netUserProperty_with_currentvalue
                    $successFlag = $false
                }
            }
        }
        catch {
            Submit-Log -text "Error inside the iteration of hash map netUserProperty_with_expectedvalue" -errorRecord $_
        }
    }

    Submit-Log -text "`n `n $($netUserProperty_with_currentvalue_array | Out-String)"
    Submit-Log -text "----------------------------- END OUTPUT -------------------------------"
    Submit-Log -text "Iteration through the fixed hash map has ended."
}

if (-not $successFlag) {
    Submit-Log -text "Success Flag Failed"
    $fileName = logFileName  -errorFileName
    Rename-Item -Path "$($logFilePath)" -NewName "$($fileName)" -Force
    $logFilePath = LogFileName  -errorFilePath
    Submit-Log -text "New LogFilePath : $($logFilePath)"
}
else {
    Submit-Log -text "Success Flag remains as default value: True"
    $fileName = logFileName -successFileName
    Rename-Item -Path "$($logFilePath)" -NewName "$($fileName)" -Force
    $logFilePath = LogFileName -successFilePath
    Submit-Log -text "New LogFilePath : $($logFilePath)"
}

Submit-Log -text "End of program"