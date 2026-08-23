param(
    [Parameter(Mandatory = $true)]
    [string]$Folder
)

$ErrorActionPreference = "Stop"

# ============================================================
# SFTP HERE
# Version 1.3.2
# Copyright (c) 2026 Aria. All rights reserved.
# ============================================================

$AppName   = "SFTP HERE"
$Version   = "1.3.2"
$Copyright = "Copyright (c) 2026 Aria. All rights reserved."

$configDir = Join-Path $env:LOCALAPPDATA "SFTPHere"

function Write-Header {
    Write-Host ""
    Write-Host "  SFTP HERE v$Version" -ForegroundColor Cyan
    Write-Host "  Instant temporary SFTP sharing" -ForegroundColor DarkGray
    Write-Host "  $Copyright" -ForegroundColor DarkGray
}

function Write-Section {
    param(
        [string]$Title
    )

    Write-Host ""
    Write-Host "  $Title" -ForegroundColor Magenta
}

function Find-SFTPGo {
    # First: portable HereTools layout
    $scriptDir = Split-Path -Parent $PSCommandPath
    $portableCandidate = Join-Path $scriptDir "..\lib\sftpgo.exe"

    if (Test-Path $portableCandidate) {
        return (Resolve-Path $portableCandidate).Path
    }

    # Then: common installed locations
    $candidates = @(
        "C:\Program Files\SFTPGo\sftpgo.exe",
        "C:\Program Files (x86)\SFTPGo\sftpgo.exe"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return (Resolve-Path $candidate).Path
        }
    }

    # Then: PATH
    try {
        $cmd = Get-Command "sftpgo.exe" -ErrorAction Stop

        if ($cmd.Source -and (Test-Path $cmd.Source)) {
            return $cmd.Source
        }
    }
    catch {}

    # Finally: limited scan
    $searchRoots = @(
        "C:\Program Files",
        "C:\Program Files (x86)",
        $env:LOCALAPPDATA
    ) | Where-Object {
        $_ -and (Test-Path $_)
    }

    foreach ($root in $searchRoots) {
        try {
            $found = Get-ChildItem `
                -Path $root `
                -Filter "sftpgo.exe" `
                -File `
                -Recurse `
                -ErrorAction SilentlyContinue |
                Select-Object -First 1

            if ($found) {
                return $found.FullName
            }
        }
        catch {}
    }

    return $null
}

function Test-PortAvailable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$IPAddress,

        [Parameter(Mandatory = $true)]
        [int]$Port
    )

    $listener = $null

    try {
        $ip = [System.Net.IPAddress]::Parse($IPAddress)

        $listener = New-Object System.Net.Sockets.TcpListener(
            $ip,
            $Port
        )

        $listener.Start()
        return $true
    }
    catch {
        return $false
    }
    finally {
        if ($listener) {
            try {
                $listener.Stop()
            }
            catch {}
        }
    }
}

function New-RandomString {
    param(
        [int]$Length = 16,
        [string]$Characters = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789"
    )

    $bytes = New-Object byte[] $Length

    if ($PSVersionTable.PSEdition -eq "Core") {
        [System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
    }
    else {
        $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
        $rng.GetBytes($bytes)
        $rng.Dispose()
    }

    return -join (
        $bytes | ForEach-Object {
            $Characters[$_ % $Characters.Length]
        }
    )
}

try {
    if (-not (Test-Path $Folder)) {
        throw "Folder not found: $Folder"
    }

    $Folder = (Resolve-Path $Folder).Path

    $sftpgo = Find-SFTPGo

    if (-not $sftpgo) {
        throw "SFTPGo could not be found."
    }

    if (-not (Test-Path $configDir)) {
        New-Item `
            -ItemType Directory `
            -Path $configDir `
            -Force | Out-Null
    }

    # ------------------------------------------------------------
    # Discover IPv4 interfaces
    # ------------------------------------------------------------

    $interfaces = @()

    $interfaces += [PSCustomObject]@{
        IP        = "127.0.0.1"
        Interface = "Loopback"
    }

    $networkIPs = Get-NetIPAddress `
        -AddressFamily IPv4 `
        -ErrorAction SilentlyContinue |
        Where-Object {
            $_.IPAddress -ne "127.0.0.1" -and
            $_.IPAddress -notlike "169.254.*"
        } |
        Sort-Object InterfaceAlias, IPAddress

    foreach ($item in $networkIPs) {
        $interfaces += [PSCustomObject]@{
            IP        = $item.IPAddress
            Interface = $item.InterfaceAlias
        }
    }

    # ------------------------------------------------------------
    # Interface selection UI
    # ------------------------------------------------------------

    Clear-Host
    Write-Header

    Write-Section "SHARED FOLDER"
    Write-Host "  $Folder" -ForegroundColor White

    Write-Section "SELECT NETWORK INTERFACE"

    for ($i = 0; $i -lt $interfaces.Count; $i++) {
        $num  = $i + 1
        $ip   = $interfaces[$i].IP
        $name = $interfaces[$i].Interface

        Write-Host ("  [{0}]" -f $num) -ForegroundColor Cyan -NoNewline
        Write-Host ("  {0,-18}" -f $ip) -ForegroundColor White -NoNewline
        Write-Host $name -ForegroundColor DarkGray
    }

    Write-Host ""

    do {
        $choice = Read-Host "  Select interface"

        $validChoice =
            $choice -match '^\d+$' -and
            [int]$choice -ge 1 -and
            [int]$choice -le $interfaces.Count

        if (-not $validChoice) {
            Write-Host "  Invalid selection." -ForegroundColor Yellow
        }

    } until ($validChoice)

    $bindIP   = $interfaces[[int]$choice - 1].IP
    $bindName = $interfaces[[int]$choice - 1].Interface

    # ------------------------------------------------------------
    # Suggest available port
    # ------------------------------------------------------------

    do {
        $suggestedPort = Get-Random -Minimum 20000 -Maximum 45000
    }
    until (
        Test-PortAvailable `
            -IPAddress $bindIP `
            -Port $suggestedPort
    )

    do {
        $portInput = Read-Host "  Port [$suggestedPort]"

        if ([string]::IsNullOrWhiteSpace($portInput)) {
            $port = $suggestedPort
        }
        elseif ($portInput -match '^\d+$') {
            $port = [int]$portInput
        }
        else {
            Write-Host "  Invalid port." -ForegroundColor Yellow
            $port = $null
            continue
        }

        if ($port -lt 1024 -or $port -gt 65535) {
            Write-Host "  Port must be between 1024 and 65535." -ForegroundColor Yellow
            $port = $null
            continue
        }

        if (-not (
            Test-PortAvailable `
                -IPAddress $bindIP `
                -Port $port
        )) {
            Write-Host "  Port $port is not available on $bindIP." -ForegroundColor Yellow
            $port = $null
            continue
        }

    } until ($port)

    # ------------------------------------------------------------
    # Generate random username and password
    # ------------------------------------------------------------

    $username = "u" + (
        New-RandomString `
            -Length 9 `
            -Characters "abcdefghijkmnopqrstuvwxyz23456789"
    )

    $password = New-RandomString -Length 20

    # ------------------------------------------------------------
    # Final UI
    # ------------------------------------------------------------

    Clear-Host
    Write-Header

    Write-Host ""
    Write-Host "  LISTENING" -ForegroundColor Green

    Write-Section "SHARED FOLDER"
    Write-Host "  $Folder" -ForegroundColor White

    Write-Section "NETWORK"

    Write-Host "  Interface : " -ForegroundColor DarkGray -NoNewline
    Write-Host "$bindName" -ForegroundColor White

    Write-Host "  Address   : " -ForegroundColor DarkGray -NoNewline
    Write-Host "$bindIP" -ForegroundColor Cyan

    Write-Host "  Port      : " -ForegroundColor DarkGray -NoNewline
    Write-Host "$port" -ForegroundColor Cyan

    Write-Section "CONNECT"

    Write-Host "  sftp -P $port $username@$bindIP" -ForegroundColor Green

    Write-Section "CREDENTIALS"

    Write-Host "  Username : " -ForegroundColor DarkGray -NoNewline
    Write-Host "$username" -ForegroundColor Yellow

    Write-Host "  Password : " -ForegroundColor DarkGray -NoNewline
    Write-Host "$password" -ForegroundColor Yellow

    Write-Host ""
    Write-Host "  Keep this window open while the share is active." -ForegroundColor DarkGray
    Write-Host "  Close this window to stop sharing." -ForegroundColor DarkGray
    Write-Host ""

    # ------------------------------------------------------------
    # Bind SFTPGo only to selected interface
    # ------------------------------------------------------------

    $env:SFTPGO_SFTPD__BINDINGS__0__ADDRESS = $bindIP

    Push-Location $configDir

    try {
        & $sftpgo portable `
            --config-dir $configDir `
            --directory $Folder `
            --username $username `
            --password $password `
            --permissions "*" `
            --sftpd-port $port `
            --log-level error `
            --log-file-path "NUL"
    }
    finally {
        Pop-Location

        Remove-Item `
            Env:SFTPGO_SFTPD__BINDINGS__0__ADDRESS `
            -ErrorAction SilentlyContinue
    }
}
catch {
    Clear-Host
    Write-Header

    Write-Host ""
    Write-Host "  ERROR" -ForegroundColor Red
    Write-Host ""
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""

    Read-Host "  Press Enter to close"
}