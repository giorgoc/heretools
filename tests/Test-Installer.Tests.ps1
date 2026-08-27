$root = Split-Path $PSScriptRoot -Parent
It 'installer validates CLI files and uses the package root' { $text = Get-Content -Raw (Join-Path $root 'install.ps1'); Assert-Contains $text 'heretools.ps1'; Assert-Contains $text 'heretools.cmd'; Assert-Contains $text '$PSScriptRoot' }
It 'installer writes only the current user PATH' { $text = Get-Content -Raw (Join-Path $root 'install.ps1'); Assert-Contains $text 'SetEnvironmentVariable'; Assert-Contains $text '"User"'; Assert-True (-not ($text -match 'SetEnvironmentVariable\([^)]*"Machine"')) }
It 'installer compares normalized exact PATH entries' { $text = Get-Content -Raw (Join-Path $root 'install.ps1'); Assert-Contains $text 'OrdinalIgnoreCase'; Assert-Contains $text 'TrimEnd' }
It 'installer preserves Explorer registrations' { $text = Get-Content -Raw (Join-Path $root 'install.ps1'); Assert-Contains $text 'Directory\shell\HereTools'; Assert-Contains $text 'Directory\Background\shell\HereTools' }
It 'uninstaller removes only the exact package-root PATH entry' { $text = Get-Content -Raw (Join-Path $root 'uninstall.ps1'); Assert-Contains $text 'OrdinalIgnoreCase'; Assert-Contains $text 'SetEnvironmentVariable'; Assert-Contains $text '"User"' }
It 'uninstaller preserves context-menu cleanup' { Assert-Contains (Get-Content -Raw (Join-Path $root 'uninstall.ps1')) 'SFTPHere' }
