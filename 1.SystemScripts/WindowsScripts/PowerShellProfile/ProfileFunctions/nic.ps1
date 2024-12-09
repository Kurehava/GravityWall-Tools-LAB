function nic(){
  param (
      [switch]$ALL,
      [switch]$INFO,
      [string]$Sort = "Status"  # デフォルトで Status によるソート
  )

  Write-Host 'Analyzing....'

  # Get-NetAdapter を一度だけ実行してキャッシュ
  $adapters = Get-NetAdapter -ErrorAction SilentlyContinue

  # 結果の取得
  $results = Get-NetIPConfiguration | ForEach-Object {
      $adapter = $_.InterfaceAlias
      $ip = $_.IPv4Address.IPAddress

      # IPアドレスがない場合の処理
      if (-not $ip) {
          $ip = "No IP Address"
      } else {
          $ip = $ip -join "`n" # IPアドレスを改行で区切って表示
      }

      # キャッシュされた Get-NetAdapter から MACアドレスを取得
      $adapterInfo = $adapters | Where-Object { $_.Name -eq $adapter }
      $macAddress = if ($adapterInfo.MacAddress -match '^[0-9A-Fa-f]{2}(-[0-9A-Fa-f]{2}){5}$') { 
          $adapterInfo.MacAddress
      } else { 
          "No MAC Address"
      }

      # デフォルトゲートウェイの取得
      $gateway = $_.IPv4DefaultGateway.NextHop
      if (-not $gateway) {
          $gateway = "No Default Gateway"
      }

      # Status の取得
      $status = if ($ALL) {
          $adapterInfo.Status
      } else {
          if ($adapterInfo.Status -eq 'Up') {
              "〇"
          } else {
              "✕"
          }
      }

      # カスタムオブジェクト作成 (mode が指定された場合 ItfIdx を表示)
      if ($ALL) {
          [PSCustomObject]@{
              Name         = $adapter
              ItfIdx       = $_.InterfaceIndex
              Status       = $status
              MACAddress   = $macAddress # MACアドレスを最後に移動
              DefaultGateway = $gateway
              IPAddress    = $ip
          }
        } elseif ($INFO) {
          [PSCustomObject]@{
            Name         = $adapter
            Status       = $status
            MACAddress   = $macAddress # MACアドレスを最後に移動
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

  # カラムの存在確認
  if ($results | Get-Member -Name $Sort -ErrorAction SilentlyContinue) {
      # ソート処理
      if ($Sort -eq "Status") {
          # デフォルトで Status によるソート (〇 -> ✕ の順)
          $results | Sort-Object {[string]$_.Status -replace '〇','0' -replace '✕','1'} | Format-Table -AutoSize -Wrap
      } else {
          # 他のカラムでソート
          $results | Sort-Object $Sort | Format-Table -AutoSize -Wrap
      }
  } else {
      # 指定された Sort カラムが存在しない場合の処理
      Write-Host "`"$Sort`" は存在しません。Status に従ってソートします。" -ForegroundColor Red
      # Status に従ってソート
      $results | Sort-Object {[string]$_.Status -replace '〇','0' -replace '✕','1'} | Format-Table -AutoSize -Wrap
  }
}
