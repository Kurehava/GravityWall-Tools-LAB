Get-Content .\<SUM_VALUE_LIST_FILE_NAME> | ForEach-Object {
    if ($_ -match '^([a-fA-F0-9]{64})\s+(.+)$') {
        $expected = $Matches[1].ToLower()
        $file = $Matches[2].Trim()
        if (Test-Path $file) {
            $actual = (Get-FileHash -Path $file -Algorithm SHA256).Hash.ToLower()
            if ($actual -eq $expected) {
                Write-Host "✅ OK: $file" -ForegroundColor Green
            } else {
                Write-Warning "❌ NG (不一致): $file"
            }
        } else {
            Write-Warning "⚠️ ファイルが見つかりません: $file"
        }
    }
}
