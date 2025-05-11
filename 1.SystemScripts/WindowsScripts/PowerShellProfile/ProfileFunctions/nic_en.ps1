function nic(){
  param (
      [switch]$ALL,
      [switch]$INFO,
      [string]$Sort = "Status"
  )

  Write-Host 'Analyzing....'

  $adapters = Get-NetAdapter -ErrorAction SilentlyContinue

  $results = Get-NetIPConfiguration | ForEach-Object {
      $adapter = $_.InterfaceAlias
      $ip = $_.IPv4Address.IPAddress

      if (-not $ip) {
          $ip = "No IP Address"
      } else {
          $ip = $ip -join "`n"
      }

      $adapterInfo = $adapters | Where-Object { $_.Name -eq $adapter }
      $macAddress = if ($adapterInfo.MacAddress -match '^[0-9A-Fa-f]{2}(-[0-9A-Fa-f]{2}){5}$') { 
          $adapterInfo.MacAddress
      } else { 
          "No MAC Address"
      }

      $gateway = $_.IPv4DefaultGateway.NextHop
      if (-not $gateway) {
          $gateway = "No Default Gateway"
      }

      # Status の取得
      $status = if ($ALL) {
          $adapterInfo.Status
      } else {
          if ($adapterInfo.Status -eq 'Up') {
              "O"
          } else {
              "X"
          }
      }

      if ($ALL) {
          [PSCustomObject]@{
              Name         = $adapter
              ItfIdx       = $_.InterfaceIndex
              Status       = $status
              MACAddress   = $macAddress
              DefaultGateway = $gateway
              IPAddress    = $ip
          }
        } elseif ($INFO) {
          [PSCustomObject]@{
            Name         = $adapter
            Status       = $status
            MACAddress   = $macAddress
            DefaultGateway = $gateway
            IPAddress    = $ip
          }
        } else {
          [PSCustomObject]@{
              Name         = $adapter
              Status       = $status
              IPAddress    = $ip
          }
      }
  }

  if ($results | Get-Member -Name $Sort -ErrorAction SilentlyContinue) {
      if ($Sort -eq "Status") {
          $results | Sort-Object {[string]$_.Status -replace 'O','0' -replace 'X','1'} | Format-Table -AutoSize -Wrap
      } else {
          $results | Sort-Object $Sort | Format-Table -AutoSize -Wrap
      }
  } else {
      Write-Host "Can not found `"$Sort`". Follow in Status Env." -ForegroundColor Red
      $results | Sort-Object {[string]$_.Status -replace 'O','0' -replace 'X','1'} | Format-Table -AutoSize -Wrap
  }
}
