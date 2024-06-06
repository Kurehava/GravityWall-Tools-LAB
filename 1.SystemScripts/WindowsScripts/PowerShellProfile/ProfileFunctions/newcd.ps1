function newls(){
  if($Args[0] -eq "-all" -or $Args[0] -eq "-a"){
    Get-ChildItem | Select-Object Mode,LastWriteTime,Length,Name | ft -Wrap
  }else{
    Get-ChildItem | Select-Object Mode,LastWriteTime,Length,Name
  }
}

function newcd(){
  Set-Location $Args[0]
  newls
}
