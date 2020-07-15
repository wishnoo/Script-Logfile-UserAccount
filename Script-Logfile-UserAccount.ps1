$temp = net user STEALTH
$temp | ForEach-Object {
    if ($_ | findstr /c:"Password expires" | findstr /c:"Never"){
        if ($_ | findstr /c:"Never") {
            Write-Verbose "Password Never Expires" -Verbose
        }
        else {
            Write-Verbose "Password Does Expire" -Verbose
        }
    }
}