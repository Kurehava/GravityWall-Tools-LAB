function prompt {
    $isRoot = (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
    $color  = if ($isRoot) {"Red"} else {"Green"}
    $marker = if ($isRoot) {"#"}   else {"$"}
    $fn = (Get-Location).Path -Split "\\" | Select-Object -Last 1

    Write-Host ""
    Write-Host "|-$pwd\~" -ForegroundColor $color
    Write-Host "|-$env:USERNAME" -ForegroundColor $color -NoNewline
    Write-Host "::" -ForegroundColor Yellow -NoNewline
    Write-Host "$fn" -ForegroundColor Cyan -NoNewline
    Write-Host "::" -ForegroundColor Yellow -NoNewline
    Write-Host $marker -ForegroundColor $color -NoNewline
    return " "
  }
Clear-Host

function ll {
  python "C:\Program Files\PowerShell\7\modify_ls.py" $pwd $args
  return 
}

Write-Host "Use 'conda activate env-name' to change env environment." -ForegroundColor "Yellow"
Write-Host "Use 'conda create -n env-name' to create new env environment." -ForegroundColor "Yellow"
conda env list

# Set-Alias ls ll
