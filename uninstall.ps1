# ============================================================
# HereTools Uninstaller
# Version 2.1.0
# Copyright (c) 2026 Aria. All rights reserved.
# ============================================================

$ErrorActionPreference = "Stop"

try {
    $removed = $false

    # ------------------------------------------------------------
    # Remove current HereTools parent menus
    # ------------------------------------------------------------

    $targets = @(
        'HKCU:\Software\Classes\Directory\shell\HereTools',
        'HKCU:\Software\Classes\Directory\Background\shell\HereTools'
    )

    foreach ($target in $targets) {
        if (Test-Path $target) {
            Remove-Item `
                $target `
                -Recurse `
                -Force

            $removed = $true
        }
    }

    # ------------------------------------------------------------
    # Remove legacy standalone entries too
    # ------------------------------------------------------------

    $legacyTargets = @(
        'HKCU:\Software\Classes\Directory\shell\SFTPHere',
        'HKCU:\Software\Classes\Directory\Background\shell\SFTPHere',
        'HKCU:\Software\Classes\Directory\shell\FTPHere',
        'HKCU:\Software\Classes\Directory\Background\shell\FTPHere',
        'HKCU:\Software\Classes\Directory\shell\HTTPHere',
        'HKCU:\Software\Classes\Directory\Background\shell\HTTPHere'
    )

    foreach ($target in $legacyTargets) {
        if (Test-Path $target) {
            Remove-Item `
                $target `
                -Recurse `
                -Force

            $removed = $true
        }
    }

    # ------------------------------------------------------------
    # Success UI
    # ------------------------------------------------------------

    Clear-Host

    Write-Host ""
    Write-Host "  HereTools Uninstaller v2.1.0" -ForegroundColor Cyan
    Write-Host "  Copyright (c) 2026 Aria. All rights reserved." -ForegroundColor DarkGray
    Write-Host ""

    if ($removed) {
        Write-Host "  Uninstall complete." -ForegroundColor Green
    }
    else {
        Write-Host "  HereTools was not installed." -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "  Removed context menu entries for:" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "    HereTools" -ForegroundColor White
    Write-Host "      SFTP Here" -ForegroundColor Cyan
    Write-Host "      FTP Here" -ForegroundColor Cyan
    Write-Host "      HTTP Here" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  HereTools files were NOT deleted." -ForegroundColor DarkGray
    Write-Host ""
}
catch {
    Clear-Host

    Write-Host ""
    Write-Host "  HereTools Uninstaller v2.1.0" -ForegroundColor Red
    Write-Host "  Copyright (c) 2026 Aria. All rights reserved." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Uninstall failed." -ForegroundColor Red
    Write-Host ""
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host ""
}

Read-Host "  Press Enter to close"