# ============================================================
# HereTools Installer
# Version 2.3.0
# Copyright (c) 2026 Aria. All rights reserved.
# ============================================================

$ErrorActionPreference = "Stop"

try {
    $root = $PSScriptRoot

    $sftpHereScript = Join-Path $root "utils\SFTPHere.ps1"
    $ftpHereScript  = Join-Path $root "utils\FTPHere.ps1"
    $httpHereScript = Join-Path $root "utils\HTTPHere.ps1"
    $sftpGoExe      = Join-Path $root "lib\sftpgo.exe"
    $hereToolsIcon  = Join-Path $root "icons\heretools.ico"

    # ------------------------------------------------------------
    # Validate required package files
    # ------------------------------------------------------------

    if (-not (Test-Path $sftpHereScript)) {
        throw "SFTPHere.ps1 not found: $sftpHereScript"
    }

    if (-not (Test-Path $ftpHereScript)) {
        throw "FTPHere.ps1 not found: $ftpHereScript"
    }

    if (-not (Test-Path $sftpGoExe)) {
        throw "sftpgo.exe not found: $sftpGoExe"
    }

    if (-not (Test-Path $hereToolsIcon)) {
        throw "HereTools icon not found: $hereToolsIcon"
    }

    # HTTPHere.ps1 is optional
    $hasHttp = Test-Path $httpHereScript

    # ------------------------------------------------------------
    # Prefer PowerShell 7+, fallback to Windows PowerShell 5.1
    # ------------------------------------------------------------

    $pwsh = $null

    try {
        $cmd = Get-Command "pwsh.exe" -ErrorAction Stop

        if ($cmd.Source -and (Test-Path $cmd.Source)) {
            $pwsh = $cmd.Source
        }
    }
    catch {}

    if (-not $pwsh) {
        $possiblePwsh = @(
            "$env:ProgramFiles\PowerShell\7\pwsh.exe",
            "${env:ProgramFiles(x86)}\PowerShell\7\pwsh.exe"
        )

        foreach ($candidate in $possiblePwsh) {
            if ($candidate -and (Test-Path $candidate)) {
                $pwsh = $candidate
                break
            }
        }
    }

    if ($pwsh) {
        $shell = "`"$pwsh`" -NoLogo -NoProfile -ExecutionPolicy Bypass"
        $shellName = "PowerShell 7+"
    }
    else {
        $shell = "powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass"
        $shellName = "Windows PowerShell 5.1"
    }

    # ------------------------------------------------------------
    # Remove old / legacy registrations
    # ------------------------------------------------------------

    $oldTargets = @(
        'HKCU:\Software\Classes\Directory\shell\HereTools',
        'HKCU:\Software\Classes\Directory\Background\shell\HereTools',

        'HKCU:\Software\Classes\Directory\shell\SFTPHere',
        'HKCU:\Software\Classes\Directory\Background\shell\SFTPHere',

        'HKCU:\Software\Classes\Directory\shell\FTPHere',
        'HKCU:\Software\Classes\Directory\Background\shell\FTPHere',

        'HKCU:\Software\Classes\Directory\shell\HTTPHere',
        'HKCU:\Software\Classes\Directory\Background\shell\HTTPHere'
    )

    foreach ($target in $oldTargets) {
        Remove-Item `
            $target `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue
    }

    # ------------------------------------------------------------
    # Helper: create HereTools cascading menu
    # ------------------------------------------------------------

    function Install-HereToolsMenu {
        param(
            [Parameter(Mandatory = $true)]
            [string]$BasePath,

            [Parameter(Mandatory = $true)]
            [string]$FolderVariable
        )

        # --------------------------------------------------------
        # Parent: HereTools
        # Icon ONLY on this level
        # --------------------------------------------------------

        New-Item $BasePath -Force | Out-Null

        Set-ItemProperty `
            $BasePath `
            -Name "MUIVerb" `
            -Value "HereTools"

        Set-ItemProperty `
            $BasePath `
            -Name "Icon" `
            -Value $hereToolsIcon

        Set-ItemProperty `
            $BasePath `
            -Name "SubCommands" `
            -Value ""

        $subMenuRoot = Join-Path $BasePath "shell"
        New-Item $subMenuRoot -Force | Out-Null

        # --------------------------------------------------------
        # SFTP Here
        # No child icon
        # --------------------------------------------------------

        $sftpMenu = Join-Path $subMenuRoot "01_SFTPHere"

        New-Item $sftpMenu -Force | Out-Null

        Set-ItemProperty `
            $sftpMenu `
            -Name "MUIVerb" `
            -Value "SFTP Here"

        $sftpCommand = Join-Path $sftpMenu "command"

        New-Item $sftpCommand -Force | Out-Null

        Set-Item `
            $sftpCommand `
            -Value "$shell -File `"$sftpHereScript`" -Folder `"$FolderVariable`""

        # --------------------------------------------------------
        # FTP Here
        # No child icon
        # --------------------------------------------------------

        $ftpMenu = Join-Path $subMenuRoot "02_FTPHere"

        New-Item $ftpMenu -Force | Out-Null

        Set-ItemProperty `
            $ftpMenu `
            -Name "MUIVerb" `
            -Value "FTP Here"

        $ftpCommand = Join-Path $ftpMenu "command"

        New-Item $ftpCommand -Force | Out-Null

        Set-Item `
            $ftpCommand `
            -Value "$shell -File `"$ftpHereScript`" -Folder `"$FolderVariable`""

        # --------------------------------------------------------
        # HTTP Here
        # No child icon
        # --------------------------------------------------------

        if ($hasHttp) {
            $httpMenu = Join-Path $subMenuRoot "03_HTTPHere"

            New-Item $httpMenu -Force | Out-Null

            Set-ItemProperty `
                $httpMenu `
                -Name "MUIVerb" `
                -Value "HTTP Here"

            $httpCommand = Join-Path $httpMenu "command"

            New-Item $httpCommand -Force | Out-Null

            Set-Item `
                $httpCommand `
                -Value "$shell -File `"$httpHereScript`" -Folder `"$FolderVariable`""
        }
    }

    # ------------------------------------------------------------
    # Right-click ON a folder
    # ------------------------------------------------------------

    Install-HereToolsMenu `
        -BasePath 'HKCU:\Software\Classes\Directory\shell\HereTools' `
        -FolderVariable '%1'

    # ------------------------------------------------------------
    # Right-click INSIDE a folder
    # ------------------------------------------------------------

    Install-HereToolsMenu `
        -BasePath 'HKCU:\Software\Classes\Directory\Background\shell\HereTools' `
        -FolderVariable '%V'

    # ------------------------------------------------------------
    # Success UI
    # ------------------------------------------------------------

    Clear-Host

    Write-Host ""
    Write-Host "  HereTools Installer v2.3.0" -ForegroundColor Cyan
    Write-Host "  Copyright (c) 2026 Aria. All rights reserved." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Installation complete." -ForegroundColor Green
    Write-Host ""

    Write-Host "  CONTEXT MENU" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  HereTools" -ForegroundColor White
    Write-Host "    SFTP Here" -ForegroundColor Cyan
    Write-Host "    FTP Here" -ForegroundColor Cyan

    if ($hasHttp) {
        Write-Host "    HTTP Here" -ForegroundColor Cyan
    }
    else {
        Write-Host "    HTTP Here  [not installed - HTTPHere.ps1 not found]" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "  PACKAGE" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  Root      : $root" -ForegroundColor DarkGray
    Write-Host "  Icon      : $hereToolsIcon" -ForegroundColor DarkGray
    Write-Host "  SFTPGo    : $sftpGoExe" -ForegroundColor DarkGray
    Write-Host "  Launcher  : $shellName" -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "  Installed for:" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "    Right-click on a folder" -ForegroundColor White
    Write-Host "    Right-click inside a folder" -ForegroundColor White
    Write-Host ""
}
catch {
    Clear-Host

    Write-Host ""
    Write-Host "  HereTools Installer v2.3.0" -ForegroundColor Red
    Write-Host "  Copyright (c) 2026 Aria. All rights reserved." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Installation failed." -ForegroundColor Red
    Write-Host ""
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host ""
}

Read-Host "  Press Enter to close"