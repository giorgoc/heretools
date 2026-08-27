$root = Split-Path $PSScriptRoot -Parent
It 'bundled Cloudflare binary is referenced relative to the package' { $text = Get-Content -Raw (Join-Path $root 'utils\HTTPHere.ps1'); Assert-True ($text -match 'cloudflared\.exe|lib') }
It 'Cloudflare integration remains opt-in' -Skip { throw 'Requires network access and a temporary Quick Tunnel.' }
