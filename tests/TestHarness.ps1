$script:TestResults = [System.Collections.Generic.List[object]]::new()
$script:CurrentTestFile = $null

function It {
    param([string]$Name, [scriptblock]$Test, [switch]$Skip)
    if ($Skip) { $script:TestResults.Add([pscustomobject]@{ Name=$Name; Status='SKIP'; Detail='' }); return }
    try { & $Test; $script:TestResults.Add([pscustomobject]@{ Name=$Name; Status='PASS'; Detail='' }) }
    catch { $script:TestResults.Add([pscustomobject]@{ Name=$Name; Status='FAIL'; Detail=$_.Exception.Message }) }
}

function Assert-True { param([bool]$Condition, [string]$Message = 'Expected condition to be true.') if (-not $Condition) { throw $Message } }
function Assert-Equal {
    param($Expected, $Actual, [string]$Message)
    if ($Expected -ne $Actual) {
        if (-not $Message) { $Message = "Expected '$Expected', got '$Actual'." }
        throw $Message
    }
}
function Assert-Contains { param([string]$Text, [string]$Value) Assert-True ($Text.Contains($Value)) "Expected text to contain '$Value'." }
function Assert-File { param([string]$Path) Assert-True (Test-Path -LiteralPath $Path -PathType Leaf) "Missing file: $Path" }

function Invoke-ScriptCapture {
    param([string]$Script, [string[]]$Arguments = @())
    & pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File $Script @Arguments 2>&1 | Out-String
}
