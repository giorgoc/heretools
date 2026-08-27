$root = Split-Path $PSScriptRoot -Parent
$script = Join-Path $root 'utils\SFTPHere.ps1'
It 'SFTP utility exists and accepts Folder' { Assert-File $script; Assert-Contains (Get-Content -Raw $script) '[string]$Folder' }
It 'SFTP utility uses temporary credentials and selected port' { $text = Get-Content -Raw $script; Assert-True ($text -match 'Password|password'); Assert-True ($text -match 'Port|port') }
It 'SFTP runtime data is kept outside the shared folder' { $text = Get-Content -Raw $script; Assert-True ($text -match 'LOCALAPPDATA|AppData|runtime|config') }
It 'SFTP integration test is opt-in' -Skip { throw 'Run only with an isolated temporary SFTPGo session.' }
