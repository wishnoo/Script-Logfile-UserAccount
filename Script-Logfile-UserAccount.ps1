<#
netUserProperty_with_expectedvalue is a hashtable to store the netuser properties that need to be verified as the key and desired values as the values in the hashtable.
#>
$netUserProperty_with_expectedvalue = @{'Account active' = 'Yes'
                            'Password expires' = 'Never'
                            'User may change password' = 'Yes'
                            'Wishnoo' = 'Yes'
}

$netuserobject = net user STEALTH
<#
We iterate through the hashtable and find the key in the netuserobject and futher find the expected value.
This is then logged in to the verbose stream and log file.
#>
foreach ($key in $netUserProperty_with_expectedvalue.Keys) {
    if ( $netuserobject | findstr /c:"$($key)" | findstr /c:"$($netUserProperty_with_expectedvalue.$key)") {
        Write-Verbose "$($key) - $($netUserProperty_with_expectedvalue.$key)" -Verbose
    }
}
