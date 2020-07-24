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
Initialize the logfile name and have option to retrive errorfile path , errorfile name, successfile path and successfile name.
Also verify if logFileNamePrefix is available or not.
Handle other errors.
#>
function LogFileName {
    [cmdletbinding()]
    param (
        [switch] $errorFlag,
        [switch] $successFlag
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

        $fileNamePathObject = New-Object -TypeName psobject
        if ($errorFlag) {
            if ((-not $logFileNamePrefix)) {
                $outputFilename = "$($compName)_ERROR.txt"
                $logFilePath = $currentFolderPath + $outputFilename
                $fileNamePathObject | Add-Member -MemberType NoteProperty -Name Name -Value $outputFilename
                $fileNamePathObject | Add-Member -MemberType NoteProperty -Name Path -Value $logFilePath
                return $fileNamePathObject
            }
            elseif (($logFileNamePrefix)) {
                $outputFilename = "$($logFileNamePrefix)_$($compName)_ERROR.txt"
                $logFilePath = $currentFolderPath + $outputFilename
                $fileNamePathObject | Add-Member -MemberType NoteProperty -Name Name -Value $outputFilename
                $fileNamePathObject | Add-Member -MemberType NoteProperty -Name Path -Value $logFilePath
                return $fileNamePathObject
            }
            else {
                $outputFilename = "ERROR.txt"
                $logFilePath = $currentFolderPath + $outputFilename
                $fileNamePathObject | Add-Member -MemberType NoteProperty -Name Name -Value $outputFilename
                $fileNamePathObject | Add-Member -MemberType NoteProperty -Name Path -Value $logFilePath
                return $fileNamePathObject
            }
        }
        elseif ($successFlag) {
            if ((-not $logFileNamePrefix)) {
                $outputFilename = "$($compName)_SUCCESS.txt"
                $logFilePath = $currentFolderPath + $outputFilename
                $fileNamePathObject | Add-Member -MemberType NoteProperty -Name Name -Value $outputFilename
                $fileNamePathObject | Add-Member -MemberType NoteProperty -Name Path -Value $logFilePath
                return $fileNamePathObject
            }
            elseif (($logFileNamePrefix)) {
                $outputFilename = "$($logFileNamePrefix)_$($compName)_SUCCESS.txt"
                $logFilePath = $currentFolderPath + $outputFilename
                $fileNamePathObject | Add-Member -MemberType NoteProperty -Name Name -Value $outputFilename
                $fileNamePathObject | Add-Member -MemberType NoteProperty -Name Path -Value $logFilePath
                return $fileNamePathObject            }
            else {
                $outputFilename = "SUCCESS.txt"
                $logFilePath = $currentFolderPath + $outputFilename
                $fileNamePathObject | Add-Member -MemberType NoteProperty -Name Name -Value $outputFilename
                $fileNamePathObject | Add-Member -MemberType NoteProperty -Name Path -Value $logFilePath
                return $fileNamePathObject            }
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
        $fileObject = logFileName  -errorFlag
        $logFilePath = $fileObject.Path
        Submit-Log -text "New LogFilePath : $($logFilePath)"
        Submit-Log -text "Error while Initializing logfilename" -errorRecord $_
        exit
    }
}


<#
Submit-Error Function aggregates the step when an error is encountered.
#>
function Submit-Error {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String] $text
    )
    if ($logFilePath) {
        $fileObject = logFileName  -errorFlag
        Rename-Item -Path "$($logFilePath)" -NewName "$($fileObject.Name)" -Force
    }
    <#
    Change the logFilePath even if the logFilePath is empty or not and hence no else statement.
    #>
    $fileObject = logFileName  -errorFlag
    $script:logFilePath = $fileObject.Path
    if ($text) {
        Submit-Log -text "$($text)"
    }
    Submit-Log -text "New LogFilePath : $($logFilePath)"
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
            Submit-Log -text "Account Name Array is Empty"
            Submit-Error
            exit
        }
        Submit-Log -text "ParameterValidation Function ended"
    }
    catch {
        Submit-Log -text "Error while excecuting within ParameterValidation Function" -errorRecord $_
        Submit-Error
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

<#
Delete any text files in the current folder
#>
$currentFolderPath = Split-Path $script:MyInvocation.MyCommand.Path
$currentFolderPath += '\'

if (Get-ChildItem -Path $currentFolderPath*.txt) {
    remove-item $currentFolderPath*.txt
}

Write-Verbose "File Name Prefix: $($logFileNamePrefix)" -Verbose
$logFilePath = LogFileName
Write-Verbose "Prevalidated Log File Path: $($logFilePath)" -verbose

<#
Cannot execute this if statement within logFileName as Submit-Log is below logFileName and cannot be called within it.
#>
if (-not $logFilePath) {
    Submit-Error
    Submit-Log -text "Log File Path is empty"
    exit
}

Submit-Log -text "Start of program - LogFilePath initialized"
Submit-Log -text "New LogFilePath : $($logFilePath)"

<#
Calling parameterValidation function
#>
try {
    ParameterValidation $AccountName
    Submit-Log -text "AccountName array Not empty"
}
catch {
    Submit-Log -text "Error while calling ParameterValidation Function" -errorRecord $_
    Submit-Error
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
        Submit-Log -text "Error while excecuting net user. Possibly wrong username" -errorRecord $_
        Submit-Error
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
            # Find the array index which contains the key.
            if ( $netuserobject | findstr /c:"$($key)") {
                # After finding the key now find the if the array value has the value of the key's value
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
            Submit-Error
            exit
        }
    }
    # Out-String is used to convert to string as write-verbose only accepts strings.
    Submit-Log -text "`n `n $($netUserProperty_with_currentvalue_array | Out-String)"
    Submit-Log -text "----------------------------- END OUTPUT -------------------------------"
    Submit-Log -text "Iteration through the fixed hash map has ended."
}

if (-not $successFlag) {
    Submit-Log -text "Success Flag Failed"
    Submit-Error
}
else {
    Submit-Log -text "Success Flag remains as default value: True"
    $fileObject = LogFileName -successFlag
    $fileName = $fileObject.Name
    Rename-Item -Path "$($logFilePath)" -NewName "$($fileName)" -Force
    $logFilePath = $fileObject.Path
    Submit-Log -text "New LogFilePath : $($logFilePath)"
}
Submit-Log -text "End of program"