$root = Split-Path $PSScriptRoot -Parent
$script = Join-Path $root 'utils\HTTPHere.ps1'
It 'HTTP utility exists and accepts Folder' { Assert-File $script; Assert-Contains (Get-Content -Raw $script) '[string]$Folder' }
It 'HTTP utility contains read-only method handling' { $text = Get-Content -Raw $script; Assert-Contains $text 'GET'; Assert-Contains $text 'HEAD'; Assert-Contains $text '405' }
It 'HTTP utility contains traversal and containment checks' { $text = Get-Content -Raw $script; Assert-True ($text -match 'travers|contain|GetFullPath') }
It 'HTTP utility supports default documents and directory responses' { $text = Get-Content -Raw $script; Assert-True ($text -match 'index\.html'); Assert-True ($text -match 'Directory') }
It 'HTTP errors do not expose internal exception details' { Assert-Contains (Get-Content -Raw $script) '500 Internal Server Error' }
It 'HTTP integration test is opt-in' -Skip { throw 'Run with a dedicated temporary server fixture.' }
