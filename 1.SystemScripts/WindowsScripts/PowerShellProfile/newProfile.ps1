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
    Set-Location $args[0]
    newls
}

Set-Alias ls newls
Set-Alias -Name cd -Value newcd -Option AllScope
