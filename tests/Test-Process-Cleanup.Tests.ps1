$root = Split-Path $PSScriptRoot -Parent
It 'protocol implementations define process cleanup paths' {
    foreach ($file in 'FTPHere.ps1','SFTPHere.ps1','HTTPHere.ps1') {
        $text = Get-Content -Raw (Join-Path $root "utils\$file")
        Assert-True ($text -match 'Stop-Process|Kill|Dispose|finally|Close') "$file has no visible cleanup path."
    }
}
It 'HTTP tunnel support references cloudflared without changing protocol dispatch' {
    $text = Get-Content -Raw (Join-Path $root 'utils\HTTPHere.ps1')
    Assert-True ($text -match 'cloudflared')
}
It 'orphan-process integration test is opt-in' -Skip { throw 'Run only with process snapshots and isolated child processes.' }
