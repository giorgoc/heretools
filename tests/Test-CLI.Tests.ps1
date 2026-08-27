$root = Split-Path $PSScriptRoot -Parent
$cli = Join-Path $root 'heretools.ps1'

It 'CLI files exist' { Assert-File $cli; Assert-File (Join-Path $root 'heretools.cmd') }
It 'shows help without arguments' { $out = Invoke-ScriptCapture $cli; Assert-Contains $out 'USAGE'; Assert-Contains $out 'COMMANDS' }
It 'shows help with --help' { Assert-Contains (Invoke-ScriptCapture $cli @('--help')) 'HereTools' }
It 'shows the version' { Assert-Contains (Invoke-ScriptCapture $cli @('--version')) '2.4.0' }
It 'rejects an unknown command' { $out = Invoke-ScriptCapture $cli @('unknown'); Assert-Contains $out 'Unknown command' }
It 'supports all protocol commands in the dispatcher' {
    $text = Get-Content -Raw $cli
    foreach ($name in 'HTTPHere.ps1','FTPHere.ps1','SFTPHere.ps1') { Assert-Contains $text $name }
}
It 'resolves paths literally, including spaces' {
    $text = Get-Content -Raw $cli
    Assert-Contains $text '-LiteralPath'
    Assert-Contains $text 'Get-Location'
}
