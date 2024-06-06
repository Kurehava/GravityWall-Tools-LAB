$history = New-Object System.Collections.ArrayList

function prompt {
    $isRoot = (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
    $color  = if ($isRoot) {"Red"} else {"DarkGreen"}
    $marker = if ($isRoot) {"#"}   else {"$"}
    $ntime = Get-Date -UFormat "%T"

    Write-Host "[$ntime]" -ForegroundColor DarkYellow
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
}

function back(){
  if (($history.Count) -eq 0){
    Write-Output "can not back."
  }else{
    Set-Location $history[-1]
    $history.RemoveAt(($history.Count) - 1)
    if ($Args[0] -eq "-l" -or $args[0] -eq "--list"){
      newls
    }
    if ($history.Count -gt 500){
      $history.RemoveAt(0)
    }
  }
}

function historys(){
  if ($Args[0] -eq $null){
    $elemcount=0
    foreach ($elem in $history) {
      "${elemcount}: ${elem}"
      $elemcount += 1
    }
  }else{
    if ([int]::TryParse($Args[0], [ref]$null) -eq "True"){
      Set-Location $history[$Args[0]]
    }else{
      Write-Output "You must input a number."
    }
  }
}

Set-Alias ls newls
Set-Alias -Name cd -Value newcd -Option AllScope
function bn(){
  back
}
function bl(){
  back -l
}
