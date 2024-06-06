$history = New-Object System.Collections.ArrayList
$MAX_HISTORY = 500

function newls(){
  if($Args[0] -eq "-all" -or $Args[0] -eq "-a"){
    Get-ChildItem | Select-Object Mode,LastWriteTime,Length,Name | ft -Wrap
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
