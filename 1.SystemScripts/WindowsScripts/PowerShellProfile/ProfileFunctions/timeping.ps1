function timeping(){
  C:\WINDOWS\system32\PING.EXE $Args | ForEach-Object { "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $_" }
}

Set-Alias -Name ping -Value timeping -Option AllScope
