$root = Split-Path $PSScriptRoot -Parent
$script = Join-Path $root 'utils\FTPHere.ps1'
It 'FTP utility exists and accepts Folder' { Assert-File $script; Assert-Contains (Get-Content -Raw $script) '[string]$Folder' }
It 'FTP utility uses temporary credentials and selected port' { $text = Get-Content -Raw $script; Assert-True ($text -match 'Password|password'); Assert-True ($text -match 'Port|port') }
It 'FTP utility uses the bundled SFTPGo binary path logic' { Assert-True ((Get-Content -Raw $script) -match 'sftpgo') }
It 'FTP integration test is opt-in' -Skip { throw 'Run only with an isolated temporary SFTPGo session.' }
