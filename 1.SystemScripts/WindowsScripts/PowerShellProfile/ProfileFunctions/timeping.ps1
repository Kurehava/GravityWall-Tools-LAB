function ping {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$PingArgs
    )

    & "$env:SystemRoot\System32\PING.EXE" @PingArgs |
        ForEach-Object {
            if ($_ -eq '') {
                ''
            } else {
                "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $_"
            }
        }
}
