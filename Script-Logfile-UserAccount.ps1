Submit-Log -text "Start of program"

param (
    [Parameter()]
    [string[]]$AccountName
)

function LogFileName {
    [cmdletbinding()]
    param (
        [switch] $requireComputerName,
        [string] $fileNamePrefix,
        [switch] $errorFilePath,
        [switch] $successFilePath
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

    if (($requireComputerName) -and ($fileNamePrefix) ) {
        $outputFilename = "$($fileNamePrefix)_$($compName).txt"
        $logFilePath = $currentFolderPath + $outputFilename
        return $logFilePath
    }
    elseif ((-Not $requireComputerName) -and ($fileNamePrefix)) {
        $outputFilename = "$($fileNamePrefix).txt"
        $logFilePath = $currentFolderPath + $outputFilename
        return $logFilePath
    }
    elseif ($errorFilePath) {
        $outputFilename = "$($compName)_ERROR.txt"
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
    if ((-not $logFilePath)) {
        $logFilePath = LogFileName -errorFilePath
        $text = "Log File Path is empty"
    }

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

$fileNamePrefix = "UserAccount"
$logFilePath = LogFileName -requireComputerName -fileNamePrefix $fileNamePrefix

ParameterValidation $AccountName


# $netuserobject = net user stealth
$netuserobject = net user $AccountName

<#
netUserProperty_with_expectedvalue is a hashtable to store the netuser properties that need to be verified as the key and desired values as the values in the hashtable.
#>
$netUserProperty_with_expectedvalue = @{'Account active' = 'Yes'
                            'Password expires' = 'Never'
                            'User may change password' = 'Yes'
}


Submit-Log -text "Iteration through the fixed hash map started."
<#
We iterate through the hashtable and find the key in the netuserobject and futher find the expected value.
This is then logged in to the verbose stream and log file.
#>
foreach ($key in $netUserProperty_with_expectedvalue.Keys) {
    try {
        if ( $netuserobject | findstr /c:"$($key)") {
            if ($netuserobject | findstr /c:"$($key)" | findstr /c:"$($netUserProperty_with_expectedvalue.$key)") {
                Submit-Log -text "$($key) - $($netUserProperty_with_expectedvalue.$key) is the EXPECTED VALUE" -Verbose
            }
            else {
                $netuserobject_indexvalue = $netuserobject | findstr /c:"$($key)"
                $netuserobject_indexvalue = $netuserobject_indexvalue -split "\s\s"
                Submit-Log -text "$($key) - $($netuserobject_indexvalue[-1]) is NOT THE EXPECTED VALUE" -Verbose
            }
        }
    }
    catch {
        Submit-Log -text "Error inside the iteration of hash map netUserProperty_with_expectedvalue" -errorRecord $_
    }
}
Submit-Log -text "Iteration through the fixed hash map has ended."
Submit-Log -text "End of program"