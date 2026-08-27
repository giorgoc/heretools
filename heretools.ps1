param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

$ErrorActionPreference = "Stop"
$script:HereToolsVersion = "2.4.0"

function Show-Help {
    Write-Host ""
    Write-Host "HereTools" -ForegroundColor Cyan
    Write-Host "Simple. Temporary. Portable. Here." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "USAGE" -ForegroundColor Magenta
    Write-Host "  heretools <command> [path]" -ForegroundColor White
    Write-Host ""
    Write-Host "COMMANDS" -ForegroundColor Magenta
    Write-Host "  http      Share a folder over temporary read-only HTTP" -ForegroundColor White
    Write-Host "  ftp       Share a folder over temporary FTP" -ForegroundColor White
    Write-Host "  sftp      Share a folder over temporary SFTP" -ForegroundColor White
    Write-Host ""
    Write-Host "OPTIONS" -ForegroundColor Magenta
    Write-Host "  --help        Show this help" -ForegroundColor White
    Write-Host "  --version     Show version information" -ForegroundColor White
    Write-Host ""
    Write-Host "EXAMPLES" -ForegroundColor Magenta
    Write-Host '  heretools http' -ForegroundColor White
    Write-Host '  heretools http "C:\Sites\Demo"' -ForegroundColor White
    Write-Host '  heretools ftp "D:\Transfer"' -ForegroundColor White
    Write-Host '  heretools sftp "C:\Files"' -ForegroundColor White
    Write-Host ""
}

$Command = if ($Arguments.Count -gt 0) { $Arguments[0] } else { $null }
$Path = if ($Arguments.Count -gt 1) { $Arguments[1] } else { $null }

if ([string]::IsNullOrWhiteSpace($Command) -or $Command -in @("--help", "-h")) {
    Show-Help
    exit 0
}

if ($Command -eq "--version") {
    Write-Host "HereTools CLI v$script:HereToolsVersion"
    exit 0
}

$protocol = $Command.ToLowerInvariant()
$scriptName = switch ($protocol) {
    "http" { "HTTPHere.ps1"; break }
    "ftp"  { "FTPHere.ps1"; break }
    "sftp" { "SFTPHere.ps1"; break }
    default { $null }
}

if (-not $scriptName) {
    Write-Host "Unknown command: $Command" -ForegroundColor Red
    Write-Host "Use 'heretools --help' to see available commands." -ForegroundColor Yellow
    exit 2
}

if ($Path) {
    $folder = Resolve-Path -LiteralPath $Path -ErrorAction Stop
    if (-not (Test-Path -LiteralPath $folder.Path -PathType Container)) {
        throw "Path is not a folder: $Path"
    }
    $folder = $folder.Path
}
else {
    $folder = (Get-Location).Path
}

$utility = Join-Path $PSScriptRoot "utils\$scriptName"
if (-not (Test-Path -LiteralPath $utility -PathType Leaf)) {
    throw "Protocol utility not found: $utility"
}

& $utility -Folder $folder
exit $LASTEXITCODE
