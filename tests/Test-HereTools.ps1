param([string]$Filter = '*')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'TestHarness.ps1')

$files = Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.Tests.ps1' | Sort-Object Name
foreach ($file in $files) { $script:CurrentTestFile = $file.Name; . $file.FullName }

$selected = @($script:TestResults | Where-Object { $_.Name -like $Filter })
$selected | Format-Table Status, Name, Detail -AutoSize | Out-String | Write-Host
$failed = @($selected | Where-Object Status -eq 'FAIL').Count
$skipped = @($selected | Where-Object Status -eq 'SKIP').Count
Write-Host "Passed: $(@($selected | Where-Object Status -eq 'PASS').Count)  Failed: $failed  Skipped: $skipped"
if ($failed -gt 0) { exit 1 }
exit 0
