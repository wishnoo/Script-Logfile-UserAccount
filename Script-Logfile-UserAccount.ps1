
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
    If ( $ErrorRecord -is [System.Management.Automation.ErrorRecord] )
    {
        Submit-Log -Text "Exception.Message [$($ErrorRecord.Exception.Message)]"
        Submit-Log -Text "Exception.GetType() [$($ErrorRecord.Exception.GetType())]"
        Submit-Log -Text "Exception.InnerException.Message [$($ErrorRecord.Exception.InnerException.Message)]"
    }

}

<#
netUserProperty_with_expectedvalue is a hashtable to store the netuser properties that need to be verified as the key and desired values as the values in the hashtable.
#>
$netUserProperty_with_expectedvalue = @{'Account active' = 'Yes'
                            'Password expires' = 'Never'
                            'User may change password' = 'Yes'
}
<#
currentFolderPath - Name of the path where the executable reside relative to path of the console.
#>
$currentFolderPath = Split-Path $script:MyInvocation.MyCommand.Path 
$currentFolderPath += '\'
<#
compname - Current local computer name where the script is executed.
#>
$compName = $env:COMPUTERNAME
$outputFilename = "UserAccount_$($compName).txt"
$logFilePath = $currentFolderPath + $outputFilename
$netuserobject = net user STEALTH

Submit-Log -text "Start of program"

Submit-Log -text "Iteration through the fixed hash map started."
<#
We iterate through the hashtable and find the key in the netuserobject and futher find the expected value.
This is then logged in to the verbose stream and log file.
#>
foreach ($key in $netUserProperty_with_expectedvalue.Keys) {
    if ( $netuserobject | findstr /c:"$($key)" | findstr /c:"$($netUserProperty_with_expectedvalue.$key)") {
        Write-Verbose "$($key) - $($netUserProperty_with_expectedvalue.$key)" -Verbose
    }
}