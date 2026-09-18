$history = New-Object System.Collections.ArrayList
$MAX_HISTORY = 500
$ECHO_IPv4 = $true
$ECHO_IPv6 = $false

$Global:TitleClockTimer = [System.Timers.Timer]::new(1000)
$Global:TitleClockTimer.AutoReset = $true

Register-ObjectEvent `
    -InputObject $Global:TitleClockTimer `
    -EventName Elapsed `
    -SourceIdentifier "PwshTitleClock" `
    -Action {
        $Host.UI.RawUI.WindowTitle = "PowerShell | $(Get-Date -Format 'HH:mm:ss')"
    } | Out-Null

$Global:TitleClockTimer.Start()

function prompt {
    $ipAddressV4 = (Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.DefaultIPGateway } | Select-Object -ExpandProperty IPAddress | Where-Object { ([System.Net.IPAddress]::Parse($_)).AddressFamily -eq 'InterNetwork' }) -join ','
    $ipAddressV6 = (Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.DefaultIPGateway } | Select-Object -ExpandProperty IPAddress | Where-Object { ([System.Net.IPAddress]::Parse($_)).AddressFamily -eq 'InterNetworkV6' })  -join ', '
    $isRoot = (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
    $color  = if ($isRoot) {"Red"} else {"DarkGreen"}
    $marker = if ($isRoot) {"#"}   else {"$"}
    # $ntime = Get-Date -Format "yyyy/MM/dd HH:mm:ss"
    $ntime = Get-Date -Format "HH:mm:ss"
    $history_node = @($history).Length

    Write-Host "[hnode:$history_node]" -ForegroundColor DarkMagenta -NoNewline
    Write-Host "[$ntime]" -ForegroundColor DarkYellow
    if ($ECHO_IPv4){Write-Host "[IPv4: $ipAddressV4]" -ForegroundColor DarkGreen}
    if ($ECHO_IPv6){Write-Host "[IPv6: $ipAddressV6]" -ForegroundColor DarkGreen}
    Write-Host "[-]-" -ForegroundColor $color -nonewline
    Write-Host "$pwd\~" -ForegroundColor DarkCyan
    Write-Host "[=]-" -ForegroundColor $color -nonewline
    Write-Host "$env:USERNAME" -ForegroundColor DarkMagenta -NoNewline
    $temp = (Get-Location).Path -Split "\\" | Select-Object -Last 1
    Write-Host "::" -ForegroundColor $color -NoNewline
    Write-Host "$temp " -ForegroundColor DarkYellow -NoNewline
    Write-Host $marker -ForegroundColor $color -NoNewline
    return " "
  }
Clear-Host

function newls(){
    if($args[0] -eq "-all" -or $args[0] -eq "-a"){
        Get-ChildItem | Select-Object Mode,LastWriteTime,Length,Name | Format-Table -Wrap
    }else{
        Get-ChildItem | Select-Object Mode,LastWriteTime,Length,Name
    }
}

function newcd(){
  [void] $history.Add((Get-Location).Path)
  Set-Location $Args[0]
  newls
  if ($history.Count -gt $MAX_HISTORY){
    $history.RemoveAt(0)
  }
}

function back(){
  if (($history.Count) -eq 0){
    Write-Output "can not back."
  }else{
    Set-Location $history[-1]
    if ($Args[0] -eq "-l" -or $args[0] -eq "--list"){
      newls
    }
    $history.RemoveAt(($history.Count) - 1)
    if ($history.Count -gt $MAX_HISTORY){
      $history.RemoveAt(0)
    }
  }
}

function historys(){
  # Usage:
  #       history <number>
  if ($Args[0] -eq $null){
    $elemcount=0
    foreach ($elem in $history) {
      "${elemcount}: ${elem}"
      $elemcount += 1
    }
  }else{
    if ([int]::TryParse($Args[0], [ref]$null) -eq "True" -and [int]$Args[0] -lt $history.Count){
      Set-Location $history[$Args[0]]
      foreach ($r in $history.Count..([int]$Args[0] + 1)){
        $history.RemoveAt($r - 1)
      }
    }else{
      Write-Output "You must input a number."
    }
  }
}

function bn(){
  back
}
function bl(){
  back -l
}

#region conda initialize
# !! Contents within this block are managed by 'conda init' !!
If (Test-Path "C:\Users\oriki\anaconda3\Scripts\conda.exe") {
   (& "C:\Users\oriki\anaconda3\Scripts\conda.exe" "shell.powershell" "hook") | Out-String | ?{$_} | Invoke-Expression
}
#endregion

Set-Alias -Name ls -Value newls -Option AllScope
Set-Alias -Name cd -Value newcd -Option AllScope
