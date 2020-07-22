
param (
    [string[]] $AccountName=@(),
    [string] $logFileNamePrefix=""
)

function LogFileName {
    [cmdletbinding()]
    param (
        # [string] $fileNamePrefix,
        [switch] $errorFilePath,
        [switch] $successFilePath,
        [switch] $successFileName,
        [switch] $errorFileName
    )
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

<#
Log function to output to verbose stream as well as log into file
#>
function Submit-Log {
    [cmdletbinding()]
    param (
        [string]$text,
        $errorRecord
    )

    # logFilePath needs to be assigned beforehand
    # if ((-not $logFilePath)) {
    #     $logFilePath = LogFileName -errorFilePath
    #     $text = "Log File Path is empty"
    # }

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

function ParameterValidation {
    [cmdletbinding()]
    param (
       [string[]] $AccountName
    )
    if (-Not $AccountName) {
        Submit-Log -text "Account Name Array is Empty"
        exit
    }
}

Write-Verbose "File Name Prefix: $($logFileNamePrefix)" -Verbose
$logFilePath = LogFileName
Write-Verbose "Prevalidated Log File Path: $($logFilePath)" -verbose

if (-not $logFilePath) {
    $logFilePath = $logFilePath = LogFileName -errorFilePath
    Submit-Log -text "Log File Path is empty"
    exit
}

Submit-Log -text "Start of program"


ParameterValidation $AccountName

<#
netUserProperty_with_expectedvalue is a hashtable to store the netuser properties that need to be verified as the key and desired values as the values in the hashtable.
#>
$netUserProperty_with_expectedvalue = @{'Account active' = 'Yes'
                            'Password expires' = 'Never'
                            'User may change password' = 'Yes'
}

<#
Output Array with the resulting values from netuser and status {EXPECTED,NOT EXPECTED}
#>
$netUserProperty_with_currentvalue_array = @()

# $netuserobject = net user stealth
$netuserobject = net user $AccountName

$successFlag = $true
<#
We iterate through the hashtable and find the key in the netuserobject and futher find the expected value.
This is then logged in to the verbose stream and log file.
#>
Submit-Log -text "------------------------  OUTPUT  -------------------------------"
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
                # Submit-Log -text "$($key)`t`t`t - $($netuserobject_indexvalue[-1])`t`t is NOT THE EXPECTED VALUE" -Verbose
                $successFlag = $false
            }
        }
    }
    catch {
        Submit-Log -text "Error inside the iteration of hash map netUserProperty_with_expectedvalue" -errorRecord $_
    }
}

Submit-Log -text "`n `n $($netUserProperty_with_currentvalue_array | Out-String)"
Submit-Log -text "-------------------------------------------------------------------"
Submit-Log -text "Iteration through the fixed hash map has ended."

if (-not $successFlag) {
    Submit-Log -text "Success Flag Failed"
    $fileName = logFileName  -errorFileName
    Rename-Item -Path "$($logFilePath)" -NewName "$($fileName)" -Force
    $logFilePath = LogFileName  -errorFilePath
    Submit-Log -text "New LogFilePath : $($logFilePath)"
}
else {
    Submit-Log -text "Success Flag True"
    $fileName = logFileName -successFileName
    Rename-Item -Path "$($logFilePath)" -NewName "$($fileName)" -Force
    $logFilePath = LogFileName -successFilePath
    Submit-Log -text "New LogFilePath : $($logFilePath)"
}

Submit-Log -text "End of program"