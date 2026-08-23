param(
    [Parameter(Mandatory = $true)]
    [string]$Folder
)

$ErrorActionPreference = "Stop"

# ============================================================
# HTTP HERE
# Version 1.2.1
# Copyright (c) 2026 Aria. All rights reserved.
# ============================================================

$AppName   = "HTTP HERE"
$Version   = "1.2.1"
$Copyright = "Copyright (c) 2026 Aria. All rights reserved."

function Write-Header {
    Write-Host ""
    Write-Host "  HTTP HERE v$Version" -ForegroundColor Cyan
    Write-Host "  Instant temporary read-only HTTP sharing" -ForegroundColor DarkGray
    Write-Host "  $Copyright" -ForegroundColor DarkGray
}

function Write-Section {
    param(
        [string]$Title
    )

    Write-Host ""
    Write-Host "  $Title" -ForegroundColor Magenta
}

function Find-Cloudflared {
    $scriptDir = Split-Path -Parent $PSCommandPath
    $portableCandidate = Join-Path $scriptDir "..\lib\cloudflared.exe"

    if (Test-Path $portableCandidate) {
        return (Resolve-Path $portableCandidate).Path
    }

    $candidates = @(
        "C:\Program Files\Cloudflare\cloudflared.exe",
        "C:\Program Files (x86)\Cloudflare\cloudflared.exe"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return (Resolve-Path $candidate).Path
        }
    }

    try {
        $cmd = Get-Command "cloudflared.exe" -ErrorAction Stop

        if ($cmd.Source -and (Test-Path $cmd.Source)) {
            return $cmd.Source
        }
    }
    catch {}

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

function Get-MimeType {
    param(
        [string]$Path
    )

    $extension = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()

    switch ($extension) {
        ".html" { return "text/html; charset=utf-8" }
        ".htm"  { return "text/html; charset=utf-8" }
        ".css"  { return "text/css; charset=utf-8" }
        ".js"   { return "application/javascript; charset=utf-8" }
        ".json" { return "application/json; charset=utf-8" }
        ".xml"  { return "application/xml; charset=utf-8" }
        ".txt"  { return "text/plain; charset=utf-8" }
        ".md"   { return "text/plain; charset=utf-8" }
        ".csv"  { return "text/csv; charset=utf-8" }

        ".png"  { return "image/png" }
        ".jpg"  { return "image/jpeg" }
        ".jpeg" { return "image/jpeg" }
        ".gif"  { return "image/gif" }
        ".webp" { return "image/webp" }
        ".svg"  { return "image/svg+xml" }
        ".ico"  { return "image/x-icon" }
        ".bmp"  { return "image/bmp" }

        ".pdf"  { return "application/pdf" }
        ".zip"  { return "application/zip" }
        ".7z"   { return "application/x-7z-compressed" }
        ".rar"  { return "application/vnd.rar" }
        ".gz"   { return "application/gzip" }

        ".mp3"  { return "audio/mpeg" }
        ".wav"  { return "audio/wav" }
        ".ogg"  { return "audio/ogg" }
        ".m4a"  { return "audio/mp4" }

        ".mp4"  { return "video/mp4" }
        ".webm" { return "video/webm" }
        ".mov"  { return "video/quicktime" }
        ".avi"  { return "video/x-msvideo" }

        ".doc"  { return "application/msword" }
        ".docx" { return "application/vnd.openxmlformats-officedocument.wordprocessingml.document" }
        ".xls"  { return "application/vnd.ms-excel" }
        ".xlsx" { return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }
        ".ppt"  { return "application/vnd.ms-powerpoint" }
        ".pptx" { return "application/vnd.openxmlformats-officedocument.presentationml.presentation" }

        default { return "application/octet-stream" }
    }
}

function Convert-ToUrlPath {
    param(
        [string[]]$Segments
    )

    if (-not $Segments -or $Segments.Count -eq 0) {
        return "/"
    }

    $encoded = foreach ($segment in $Segments) {
        [System.Uri]::EscapeDataString($segment)
    }

    return "/" + ($encoded -join "/")
}

function Send-ResponseHeaders {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.Stream]$Stream,

        [Parameter(Mandatory = $true)]
        [int]$StatusCode,

        [Parameter(Mandatory = $true)]
        [string]$StatusText,

        [Parameter(Mandatory = $true)]
        [string]$ContentType,

        [Parameter(Mandatory = $true)]
        [long]$ContentLength,

        [string]$ExtraHeaders = ""
    )

    $headers =
        "HTTP/1.1 $StatusCode $StatusText`r`n" +
        "Content-Type: $ContentType`r`n" +
        "Content-Length: $ContentLength`r`n" +
        "Connection: close`r`n" +
        "Cache-Control: no-store`r`n" +
        "X-Content-Type-Options: nosniff`r`n"

    if ($ExtraHeaders) {
        $headers += $ExtraHeaders
    }

    $headers += "`r`n"

    $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($headers)
    $Stream.Write($headerBytes, 0, $headerBytes.Length)
}

function Send-TextResponse {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.Stream]$Stream,

        [int]$StatusCode = 200,

        [string]$StatusText = "OK",

        [string]$ContentType = "text/html; charset=utf-8",

        [string]$Body = "",

        [bool]$HeadOnly = $false,

        [string]$ExtraHeaders = ""
    )

    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($Body)

    Send-ResponseHeaders `
        -Stream $Stream `
        -StatusCode $StatusCode `
        -StatusText $StatusText `
        -ContentType $ContentType `
        -ContentLength $bodyBytes.Length `
        -ExtraHeaders $ExtraHeaders

    if (-not $HeadOnly -and $bodyBytes.Length -gt 0) {
        $Stream.Write($bodyBytes, 0, $bodyBytes.Length)
    }
}

function Get-ErrorPageHtml {
    param(
        [Parameter(Mandatory = $true)]
        [int]$StatusCode,

        [Parameter(Mandatory = $true)]
        [string]$StatusText,

        [string]$Message = ""
    )

    $safeStatusText = [System.Net.WebUtility]::HtmlEncode($StatusText)
    $safeMessage    = [System.Net.WebUtility]::HtmlEncode($Message)

    if ([string]::IsNullOrWhiteSpace($safeMessage)) {
        $safeMessage = "The request could not be completed."
    }

    return @"
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>$StatusCode $safeStatusText</title>
<style>
    :root {
        color-scheme: dark;
        font-family: "Segoe UI", system-ui, sans-serif;
    }

    * {
        box-sizing: border-box;
    }

    body {
        margin: 0;
        background: #0b0d10;
        color: #e7e9ec;
    }

    .wrap {
        width: min(760px, calc(100% - 32px));
        margin: 72px auto;
    }

    .brand {
        color: #67d7ff;
        font-size: 15px;
        font-weight: 650;
        margin-bottom: 32px;
    }

    .code {
        color: #dd71ff;
        font-size: 64px;
        line-height: 1;
        font-weight: 700;
    }

    h1 {
        margin: 12px 0 0;
        font-size: 28px;
        font-weight: 650;
    }

    .message {
        margin-top: 14px;
        color: #7f8792;
        font-size: 15px;
        line-height: 1.6;
    }

    footer {
        margin-top: 48px;
        color: #59616b;
        font-size: 12px;
    }
</style>
</head>
<body>
<div class="wrap">
    <div class="brand">HTTP Here</div>
    <div class="code">$StatusCode</div>
    <h1>$safeStatusText</h1>
    <div class="message">$safeMessage</div>

    <footer>
        HTTP HERE v$Version &middot; $Copyright
    </footer>
</div>
</body>
</html>
"@
}

function Send-ErrorResponse {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.Stream]$Stream,

        [Parameter(Mandatory = $true)]
        [int]$StatusCode,

        [Parameter(Mandatory = $true)]
        [string]$StatusText,

        [string]$Message = "",

        [bool]$HeadOnly = $false,

        [string]$ExtraHeaders = ""
    )

    $html = Get-ErrorPageHtml `
        -StatusCode $StatusCode `
        -StatusText $StatusText `
        -Message $Message

    Send-TextResponse `
        -Stream $Stream `
        -StatusCode $StatusCode `
        -StatusText $StatusText `
        -ContentType "text/html; charset=utf-8" `
        -Body $html `
        -HeadOnly $HeadOnly `
        -ExtraHeaders $ExtraHeaders
}

function Send-FileResponse {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.Stream]$Stream,

        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [bool]$HeadOnly = $false
    )

    $fileInfo = Get-Item -LiteralPath $FilePath
    $mimeType = Get-MimeType -Path $FilePath

    Send-ResponseHeaders `
        -Stream $Stream `
        -StatusCode 200 `
        -StatusText "OK" `
        -ContentType $mimeType `
        -ContentLength $fileInfo.Length

    if (-not $HeadOnly) {
        $fileStream = [System.IO.File]::OpenRead($FilePath)

        try {
            $buffer = New-Object byte[] 65536

            while (($read = $fileStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                $Stream.Write($buffer, 0, $read)
            }
        }
        finally {
            $fileStream.Dispose()
        }
    }
}

function Get-DirectoryListingHtml {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DirectoryPath,

        [Parameter(Mandatory = $true)]
        [string[]]$UrlSegments
    )

    $displayPath = "/"

    if ($UrlSegments.Count -gt 0) {
        $displayPath += ($UrlSegments -join "/")
    }

    $safeDisplayPath = [System.Net.WebUtility]::HtmlEncode($displayPath)

    $rows = New-Object System.Collections.Generic.List[string]

    if ($UrlSegments.Count -gt 0) {
        $parentSegments = @()

        if ($UrlSegments.Count -gt 1) {
            $parentSegments = $UrlSegments[0..($UrlSegments.Count - 2)]
        }

        $parentUrl = Convert-ToUrlPath -Segments $parentSegments

        if (-not $parentUrl.EndsWith("/")) {
            $parentUrl += "/"
        }

        $rows.Add(
            "<a class='item folder' href='$parentUrl'>" +
            "<span class='icon'>[..]</span>" +
            "<span class='name'>Parent directory</span>" +
            "</a>"
        )
    }

    $items = Get-ChildItem `
        -LiteralPath $DirectoryPath `
        -Force `
        -ErrorAction SilentlyContinue |
        Sort-Object @{ Expression = { -not $_.PSIsContainer } }, Name

    foreach ($item in $items) {
        $safeName = [System.Net.WebUtility]::HtmlEncode($item.Name)

        $newSegments = @($UrlSegments) + @($item.Name)
        $url = Convert-ToUrlPath -Segments $newSegments

        if ($item.PSIsContainer) {
            $url += "/"

            $rows.Add(
                "<a class='item folder' href='$url'>" +
                "<span class='icon'>[DIR]</span>" +
                "<span class='name'>$safeName</span>" +
                "</a>"
            )
        }
        else {
            $size = $item.Length

            if ($size -ge 1GB) {
                $sizeText = "{0:N2} GB" -f ($size / 1GB)
            }
            elseif ($size -ge 1MB) {
                $sizeText = "{0:N2} MB" -f ($size / 1MB)
            }
            elseif ($size -ge 1KB) {
                $sizeText = "{0:N1} KB" -f ($size / 1KB)
            }
            else {
                $sizeText = "$size B"
            }

            $safeSize = [System.Net.WebUtility]::HtmlEncode($sizeText)

            $rows.Add(
                "<a class='item file' href='$url'>" +
                "<span class='icon'>[FILE]</span>" +
                "<span class='name'>$safeName</span>" +
                "<span class='size'>$safeSize</span>" +
                "</a>"
            )
        }
    }

    if ($rows.Count -eq 0) {
        $rows.Add("<div class='empty'>This folder is empty.</div>")
    }

    $itemsHtml = $rows -join "`n"

    return @"
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>HTTP Here - $safeDisplayPath</title>
<style>
    :root {
        color-scheme: dark;
        font-family: "Segoe UI", system-ui, sans-serif;
    }

    * {
        box-sizing: border-box;
    }

    body {
        margin: 0;
        background: #0b0d10;
        color: #e7e9ec;
    }

    .wrap {
        width: min(900px, calc(100% - 32px));
        margin: 48px auto;
    }

    h1 {
        margin: 0;
        font-size: 28px;
        font-weight: 650;
        color: #67d7ff;
    }

    .subtitle {
        margin-top: 6px;
        color: #7f8792;
        font-size: 14px;
    }

    .path {
        margin: 34px 0 14px;
        color: #dd71ff;
        font-size: 13px;
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: .08em;
    }

    .list {
        border-radius: 10px;
        overflow: hidden;
        background: #11151a;
    }

    .item {
        display: grid;
        grid-template-columns: 70px 1fr auto;
        gap: 12px;
        align-items: center;
        padding: 14px 16px;
        color: inherit;
        text-decoration: none;
        border-bottom: 1px solid #20262e;
    }

    .item:last-child {
        border-bottom: none;
    }

    .item:hover {
        background: #171d24;
    }

    .icon {
        color: #687381;
        font-family: Consolas, monospace;
        font-size: 12px;
    }

    .folder .name {
        color: #72d9ff;
    }

    .file .name {
        color: #e7e9ec;
    }

    .size {
        color: #7f8792;
        font-size: 13px;
        padding-left: 16px;
    }

    .empty {
        color: #7f8792;
        padding: 18px;
    }

    footer {
        margin-top: 28px;
        color: #59616b;
        font-size: 12px;
    }
</style>
</head>
<body>
<div class="wrap">
    <h1>HTTP Here</h1>
    <div class="subtitle">Temporary read-only file sharing</div>

    <div class="path">$safeDisplayPath</div>

    <div class="list">
        $itemsHtml
    </div>

    <footer>
        HTTP HERE v$Version &middot; $Copyright
    </footer>
</div>
</body>
</html>
"@
}

function Start-CloudflareQuickTunnel {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CloudflaredPath,

        [Parameter(Mandatory = $true)]
        [string]$LocalUrl
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $CloudflaredPath
    $psi.Arguments = "tunnel --url `"$LocalUrl`" --no-autoupdate"
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi

    if (-not $process.Start()) {
        throw "Unable to start cloudflared."
    }

    $deadline = [DateTime]::UtcNow.AddSeconds(25)
    $publicUrl = $null

    while ([DateTime]::UtcNow -lt $deadline) {
        if ($process.HasExited) {
            $stderr = $process.StandardError.ReadToEnd()

            if ([string]::IsNullOrWhiteSpace($stderr)) {
                $stderr = "cloudflared exited before creating a tunnel."
            }

            throw $stderr.Trim()
        }

        while (-not $process.StandardError.EndOfStream) {
            $line = $process.StandardError.ReadLine()

            if ($line -match 'https://[A-Za-z0-9\-]+\.trycloudflare\.com') {
                $publicUrl = $Matches[0]
                break
            }
        }

        if ($publicUrl) {
            break
        }

        Start-Sleep -Milliseconds 150
    }

    if (-not $publicUrl) {
        try {
            if (-not $process.HasExited) {
                $process.Kill()
            }
        }
        catch {}

        throw "Cloudflare Quick Tunnel did not return a public URL."
    }

    return [PSCustomObject]@{
        Process = $process
        Url     = $publicUrl
    }
}

try {
    if (-not (Test-Path -LiteralPath $Folder -PathType Container)) {
        throw "Folder not found: $Folder"
    }

    $Folder = (Resolve-Path -LiteralPath $Folder).Path.TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    )

    $cloudflared   = Find-Cloudflared
    $hasCloudflare = $null -ne $cloudflared

    # ------------------------------------------------------------
    # Build available local interfaces
    # ------------------------------------------------------------

    $interfaces = @()

    $interfaces += [PSCustomObject]@{
        Type      = "Local"
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
            Type      = "Local"
            IP        = $item.IPAddress
            Interface = $item.InterfaceAlias
        }
    }

    if ($hasCloudflare) {
        $interfaces += [PSCustomObject]@{
            Type      = "Tunnel"
            IP        = $null
            Interface = "Cloudflare"
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
        $item = $interfaces[$i]

        if ($item.Type -eq "Local") {
            Write-Host ("  [{0}]" -f $num) -ForegroundColor Cyan -NoNewline
            Write-Host ("  {0,-18}" -f $item.IP) -ForegroundColor White -NoNewline
            Write-Host $item.Interface -ForegroundColor DarkGray
        }
        else {
            Write-Host ("  [{0}]" -f $num) -ForegroundColor Cyan -NoNewline
            Write-Host ("  {0,-18}" -f "Public Tunnel") -ForegroundColor White -NoNewline
            Write-Host "Cloudflare" -ForegroundColor DarkGray
        }
    }

    Write-Host ""

    if ($hasCloudflare) {
        $defaultChoice = $interfaces.Count
    }
    else {
        $defaultChoice = 1
    }

    do {
        $choiceInput = Read-Host "  Select interface [$defaultChoice]"

        if ([string]::IsNullOrWhiteSpace($choiceInput)) {
            $choice = $defaultChoice
        }
        else {
            $choice = $choiceInput
        }

        $validChoice =
            $choice -match '^\d+$' -and
            [int]$choice -ge 1 -and
            [int]$choice -le $interfaces.Count

        if (-not $validChoice) {
            Write-Host "  Invalid selection." -ForegroundColor Yellow
        }

    } until ($validChoice)

    $selected  = $interfaces[[int]$choice - 1]
    $useTunnel = $selected.Type -eq "Tunnel"

    if ($useTunnel) {
        $bindIP   = "127.0.0.1"
        $bindName = "Cloudflare Tunnel"
    }
    else {
        $bindIP   = $selected.IP
        $bindName = $selected.Interface
    }

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
    # Start HTTP listener
    # ------------------------------------------------------------

    $ipAddress = [System.Net.IPAddress]::Parse($bindIP)

    $listener = New-Object System.Net.Sockets.TcpListener(
        $ipAddress,
        $port
    )

    $listener.Start()

    $localUrl   = "http://$bindIP`:$port/"
    $connectUrl = $localUrl

    # ------------------------------------------------------------
    # Optional Cloudflare Quick Tunnel
    # ------------------------------------------------------------

    $cloudflareProcess = $null

    if ($useTunnel) {
        Clear-Host
        Write-Header

        Write-Host ""
        Write-Host "  STARTING TUNNEL" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Creating temporary Cloudflare public URL..." -ForegroundColor DarkGray
        Write-Host ""

        $tunnel = Start-CloudflareQuickTunnel `
            -CloudflaredPath $cloudflared `
            -LocalUrl $localUrl

        $cloudflareProcess = $tunnel.Process
        $connectUrl = $tunnel.Url.TrimEnd("/") + "/"
    }

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

    if ($useTunnel) {
        Write-Host "  Interface : " -ForegroundColor DarkGray -NoNewline
        Write-Host "Cloudflare Public Tunnel" -ForegroundColor White

        Write-Host "  Local     : " -ForegroundColor DarkGray -NoNewline
        Write-Host "$bindIP`:$port" -ForegroundColor Cyan

        Write-Host "  Public    : " -ForegroundColor DarkGray -NoNewline
        Write-Host "$connectUrl" -ForegroundColor Cyan
    }
    else {
        Write-Host "  Interface : " -ForegroundColor DarkGray -NoNewline
        Write-Host "$bindName" -ForegroundColor White

        Write-Host "  Address   : " -ForegroundColor DarkGray -NoNewline
        Write-Host "$bindIP" -ForegroundColor Cyan

        Write-Host "  Port      : " -ForegroundColor DarkGray -NoNewline
        Write-Host "$port" -ForegroundColor Cyan
    }

    Write-Section "CONNECT"
    Write-Host "  $connectUrl" -ForegroundColor Green

    Write-Host ""
    Write-Host "  Read-only sharing. No upload, edit or delete." -ForegroundColor DarkGray

    if ($useTunnel) {
        Write-Host "  Public access is active through Cloudflare Quick Tunnel." -ForegroundColor DarkGray
    }

    Write-Host "  Keep this window open while the share is active." -ForegroundColor DarkGray
    Write-Host "  Close this window to stop sharing." -ForegroundColor DarkGray
    Write-Host ""

    # ------------------------------------------------------------
    # HTTP server loop
    # ------------------------------------------------------------

    while ($true) {
        $client = $null
        $stream = $null
        $reader = $null

        try {
            if ($useTunnel -and $cloudflareProcess -and $cloudflareProcess.HasExited) {
                throw "Cloudflare tunnel stopped unexpectedly."
            }

            $client = $listener.AcceptTcpClient()
            $client.NoDelay = $true

            $stream = $client.GetStream()

            $reader = New-Object System.IO.StreamReader(
                $stream,
                [System.Text.Encoding]::ASCII,
                $false,
                8192,
                $true
            )

            $requestLine = $reader.ReadLine()

            if ([string]::IsNullOrWhiteSpace($requestLine)) {
                continue
            }

            $requestParts = $requestLine.Split(" ")

            if ($requestParts.Count -lt 2) {
                Send-ErrorResponse `
                    -Stream $stream `
                    -StatusCode 400 `
                    -StatusText "Bad Request" `
                    -Message "The HTTP request could not be understood."

                continue
            }

            $method    = $requestParts[0].ToUpperInvariant()
            $rawTarget = $requestParts[1]

            while ($true) {
                $line = $reader.ReadLine()

                if ($null -eq $line -or $line -eq "") {
                    break
                }
            }

            $headOnly = $method -eq "HEAD"

            if ($method -ne "GET" -and $method -ne "HEAD") {
                Send-ErrorResponse `
                    -Stream $stream `
                    -StatusCode 405 `
                    -StatusText "Method Not Allowed" `
                    -Message "HTTP Here supports GET and HEAD requests only." `
                    -HeadOnly $headOnly `
                    -ExtraHeaders "Allow: GET, HEAD`r`n"

                continue
            }

            $targetPath = $rawTarget.Split("?")[0]

            try {
                $decodedPath = [System.Uri]::UnescapeDataString($targetPath)
            }
            catch {
                Send-ErrorResponse `
                    -Stream $stream `
                    -StatusCode 400 `
                    -StatusText "Bad Request" `
                    -Message "The requested URL is malformed." `
                    -HeadOnly $headOnly

                continue
            }

            $decodedPath = $decodedPath.Replace("\", "/")

            $segments = @(
                $decodedPath.Trim("/") -split "/" |
                Where-Object { $_ -ne "" }
            )

            if ($segments -contains "..") {
                Send-ErrorResponse `
                    -Stream $stream `
                    -StatusCode 403 `
                    -StatusText "Forbidden" `
                    -Message "Access outside the shared folder is not allowed." `
                    -HeadOnly $headOnly

                continue
            }

            $candidate = $Folder

            foreach ($segment in $segments) {
                $candidate = Join-Path $candidate $segment
            }

            try {
                $fullCandidate = [System.IO.Path]::GetFullPath($candidate)
                $fullRoot      = [System.IO.Path]::GetFullPath($Folder)
            }
            catch {
                Send-ErrorResponse `
                    -Stream $stream `
                    -StatusCode 400 `
                    -StatusText "Bad Request" `
                    -Message "The requested path is invalid." `
                    -HeadOnly $headOnly

                continue
            }

            $rootPrefix = $fullRoot.TrimEnd(
                [System.IO.Path]::DirectorySeparatorChar,
                [System.IO.Path]::AltDirectorySeparatorChar
            ) + [System.IO.Path]::DirectorySeparatorChar

            $insideRoot =
                $fullCandidate.Equals(
                    $fullRoot,
                    [System.StringComparison]::OrdinalIgnoreCase
                ) -or
                $fullCandidate.StartsWith(
                    $rootPrefix,
                    [System.StringComparison]::OrdinalIgnoreCase
                )

            if (-not $insideRoot) {
                Send-ErrorResponse `
                    -Stream $stream `
                    -StatusCode 403 `
                    -StatusText "Forbidden" `
                    -Message "Access outside the shared folder is not allowed." `
                    -HeadOnly $headOnly

                continue
            }

            if (Test-Path -LiteralPath $fullCandidate -PathType Container) {
                if (-not $decodedPath.EndsWith("/")) {
                    $location = $targetPath + "/"
                    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes("Redirecting")

                    Send-ResponseHeaders `
                        -Stream $stream `
                        -StatusCode 301 `
                        -StatusText "Moved Permanently" `
                        -ContentType "text/plain; charset=utf-8" `
                        -ContentLength $bodyBytes.Length `
                        -ExtraHeaders "Location: $location`r`n"

                    if (-not $headOnly) {
                        $stream.Write(
                            $bodyBytes,
                            0,
                            $bodyBytes.Length
                        )
                    }

                    continue
                }

                $defaultDocument = $null

                foreach ($defaultName in @("index.html", "index.htm")) {
                    $candidateDefault = Join-Path $fullCandidate $defaultName

                    if (Test-Path -LiteralPath $candidateDefault -PathType Leaf) {
                        $defaultDocument = $candidateDefault
                        break
                    }
                }

                if ($defaultDocument) {
                    Send-FileResponse `
                        -Stream $stream `
                        -FilePath $defaultDocument `
                        -HeadOnly $headOnly

                    continue
                }

                $html = Get-DirectoryListingHtml `
                    -DirectoryPath $fullCandidate `
                    -UrlSegments $segments

                Send-TextResponse `
                    -Stream $stream `
                    -StatusCode 200 `
                    -StatusText "OK" `
                    -ContentType "text/html; charset=utf-8" `
                    -Body $html `
                    -HeadOnly $headOnly

                continue
            }

            if (Test-Path -LiteralPath $fullCandidate -PathType Leaf) {
                Send-FileResponse `
                    -Stream $stream `
                    -FilePath $fullCandidate `
                    -HeadOnly $headOnly

                continue
            }

            Send-ErrorResponse `
                -Stream $stream `
                -StatusCode 404 `
                -StatusText "Not Found" `
                -Message "The requested file or folder does not exist." `
                -HeadOnly $headOnly
        }
        catch {
            if ($stream) {
                try {
                    Send-ErrorResponse `
                        -Stream $stream `
                        -StatusCode 500 `
                        -StatusText "Internal Server Error" `
                        -Message "HTTP Here encountered an unexpected error while processing the request."
                }
                catch {}
            }
            elseif ($useTunnel -and $cloudflareProcess -and $cloudflareProcess.HasExited) {
                throw
            }
        }
        finally {
            if ($reader) {
                try { $reader.Dispose() } catch {}
            }

            if ($stream) {
                try { $stream.Dispose() } catch {}
            }

            if ($client) {
                try { $client.Close() } catch {}
            }
        }
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
finally {
    if ($listener) {
        try { $listener.Stop() } catch {}
    }

    if ($cloudflareProcess) {
        try {
            if (-not $cloudflareProcess.HasExited) {
                $cloudflareProcess.Kill()
                $cloudflareProcess.WaitForExit(3000)
            }
        }
        catch {}
    }
}