[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$statusLinePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'config\claude\statusline.ps1'

function Assert-True {
    param(
        [Parameter(Mandatory)] [bool] $Condition,
        [Parameter(Mandatory)] [string] $Message
    )

    if (-not $Condition) {
        throw "Assertion failed: $Message"
    }
}

# Run the status line in a child pwsh under the given culture and return its
# output with ANSI colours stripped unless -KeepColors is given.
function Invoke-StatusLine {
    param(
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $Payload,
        [string] $Culture = 'en-US',
        [switch] $KeepColors
    )

    $command = "[Globalization.CultureInfo]::CurrentCulture = '$Culture'; & '$statusLinePath'"
    $output = $Payload | pwsh -NoProfile -NonInteractive -Command $command
    Assert-True ($LASTEXITCODE -eq 0) "the status line exited with $LASTEXITCODE"
    $text = @($output) -join "`n"
    if ($KeepColors) { $text } else { $text -replace "$([char] 27)\[[0-9;]*m", '' }
}

$testRoot = Join-Path ([IO.Path]::GetTempPath()) ("dotfiles-statusline-test-" + [Guid]::NewGuid().ToString('N'))
$userProfile = Join-Path $testRoot 'home'
$projectDir = Join-Path $testRoot 'project'
$originalEnvironment = @{}

try {
    foreach ($name in 'USERPROFILE', 'CLAUDE_PROJECT_DIR') {
        $originalEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
    }

    New-Item -ItemType Directory -Force -Path (Join-Path $userProfile '.claude'), $projectDir | Out-Null
    $env:USERPROFILE = $userProfile
    # Outside a git repository the first segment falls back to the output style.
    $env:CLAUDE_PROJECT_DIR = $projectDir

    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $payload = @{
        model = @{ display_name = 'Opus 5.5' }
        effort = @{ level = 'medium' }
        context_window = @{
            used_percentage = 34.4
            total_input_tokens = 27000
            total_output_tokens = 1800
            context_window_size = 1000000
        }
        cost = @{ total_cost_usd = 4.1 }
        rate_limits = @{
            five_hour = @{ used_percentage = 38.2; resets_at = $now + 3730 }
            seven_day = @{ used_percentage = 81; resets_at = $now + 61230 }
        }
        fast_mode = $true
        thinking = @{ enabled = $true }
        output_style = @{ name = 'explanatory' }
    } | ConvertTo-Json -Depth 5

    $lines = @((Invoke-StatusLine -Payload $payload) -split "`n")
    Assert-True ($lines.Count -eq 4) "a full payload rendered $($lines.Count) lines instead of 4"
    Assert-True ($lines[0] -eq 'explanatory │ Opus 5.5 medium │ 🔥 ██████████ 34% │ 28.8k/1.0M │ $4.10') "unexpected first line: $($lines[0])"
    Assert-True ($lines[1] -eq '├ 5h ██████████  38%  ↺ 1h02m') "unexpected 5-hour row: $($lines[1])"
    Assert-True ($lines[2] -eq '└ 7d ██████████  81%  ↺ 17h00m') "unexpected 7-day row: $($lines[2])"
    Assert-True ($lines[3] -eq '⚡fast 🎨explanatory') "unexpected flags row: $($lines[3])"

    # Empty bar cells share the filled glyph, so check fill against the raw colours.
    $esc = [char] 27
    $colored = @((Invoke-StatusLine -Payload $payload -KeepColors) -split "`n")
    $emptyContextCells = ([regex]::Matches($colored[0], [regex]::Escape("$esc[38;5;236m█"))).Count
    Assert-True ($emptyContextCells -eq 7) "34% context left $emptyContextCells of 10 cells empty instead of 7"
    Assert-True ($colored[1].Contains("$esc[01;38;5;77m████$esc[38;5;236m██████")) '38% five-hour usage did not fill 4 green cells'
    Assert-True ($colored[2].Contains("$esc[01;38;5;196m████████$esc[38;5;236m██")) '81% seven-day usage did not fill 8 red cells'

    $usagePath = Join-Path $userProfile '.claude\usage-input.json'
    Assert-True ((Get-Content -Raw -LiteralPath $usagePath).Trim() -eq $payload) 'the payload was not published for the usage monitor'
    Assert-True (-not (Test-Path -LiteralPath "$usagePath.tmp")) 'the temporary usage file was left behind'

    $localized = @((Invoke-StatusLine -Payload $payload -Culture 'de-DE') -split "`n")
    Assert-True ($localized[0] -match '28\.8k/1\.0M │ \$4\.10$') "a comma-decimal culture changed number formatting: $($localized[0])"

    $apiPayload = @{
        model = @{ display_name = 'Sonnet 5' }
        rate_limits = @{ five_hour = @{ used_percentage = 100 } }
        thinking = @{ enabled = $true }
    } | ConvertTo-Json -Depth 5
    $apiLines = @((Invoke-StatusLine -Payload $apiPayload) -split "`n")
    Assert-True ($apiLines.Count -eq 2) "a single rate limit rendered $($apiLines.Count) lines instead of 2"
    Assert-True ($apiLines[1] -eq '├ 5h ██████████ 100%') "a rate limit without a reset time rendered: $($apiLines[1])"

    $expired = @{
        model = @{ display_name = 'Opus 5.5' }
        rate_limits = @{ seven_day = @{ used_percentage = 5; resets_at = $now - 60 } }
    } | ConvertTo-Json -Depth 5
    Assert-True ((Invoke-StatusLine -Payload $expired) -match '└ 7d ██████████   5%  ↺ now') 'an elapsed reset did not render as now'

    # printf rounds exact midpoints to even; 1250 tokens and $0.125 are exact in binary.
    $midpoint = @{
        context_window = @{ total_input_tokens = 1250; context_window_size = 200000 }
        cost = @{ total_cost_usd = 0.125 }
        thinking = @{ enabled = $true }
    } | ConvertTo-Json -Depth 5
    Assert-True ((Invoke-StatusLine -Payload $midpoint) -match '1\.2k/200\.0k │ \$0\.12$') 'midpoints did not round to even like printf'

    # Malformed values must degrade to defaults, never abort the render.
    $malformed = @{
        model = @{ display_name = 'Opus 5.5' }
        effort = @{ level = $false }
        context_window = @{ used_percentage = -5; total_input_tokens = 'lots' }
        cost = @{ total_cost_usd = 'abc' }
        rate_limits = @{
            five_hour = @{ used_percentage = 'high'; resets_at = '2026-09-23T12:00:00Z' }
            seven_day = @{ used_percentage = $false }
        }
        fast_mode = 'false'
        thinking = @{ enabled = 1 }
    } | ConvertTo-Json -Depth 5
    $malformedLines = @((Invoke-StatusLine -Payload $malformed) -split "`n")
    Assert-True ($malformedLines[0] -eq 'default │ Opus 5.5 │ 🔥 ██████████ -5% │ 0/200.0k │ $0.00') "malformed values rendered: $($malformedLines[0])"
    Assert-True ($malformedLines.Count -eq 2) "non-numeric or false rate limits were not hidden: $($malformedLines -join ' / ')"
    Assert-True ($malformedLines[1] -eq '💤thinking off') "only a literal true should toggle flags: $($malformedLines[1])"

    $fallback = (Invoke-StatusLine -Payload 'not json') -split "`n"
    Assert-True ($fallback[0] -eq 'default │ ? │ 🔥 ██████████ 0% │ 0/200.0k │ $0.00') "invalid JSON did not render the fallback line: $($fallback[0])"
    Assert-True ($fallback[1] -eq '💤thinking off') "invalid JSON did not report thinking as off: $($fallback[1])"

    Write-Host 'Status line tests passed.'
}
finally {
    foreach ($name in $originalEnvironment.Keys) {
        [Environment]::SetEnvironmentVariable($name, $originalEnvironment[$name], 'Process')
    }

    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}
