# Usage-focused status line for Claude Code.
#
#   main │ Opus 5 medium │ 🔥 ██████░░░░ 34% │ 28.8k/1.0M │ $4.10
#   ├ 5h ████░░░░░░  38%  ↺ 1h02m
#   └ 7d ████████░░  81%  ↺ 17h00m
#
# Rate-limit rows only appear for Pro/Max plans. Claude Code runs this on every
# render, so run it with -NoProfile; absent or malformed fields fall back to
# defaults instead of failing.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# An unexpected error would blank the status line; show the reason instead.
trap {
    [Console]::Out.Write("statusline.ps1: $_")
    exit 0
}

$utf8 = [System.Text.UTF8Encoding]::new($false)
[Console]::InputEncoding = $utf8
[Console]::OutputEncoding = $utf8
$invariant = [System.Globalization.CultureInfo]::InvariantCulture

$inputJson = [Console]::In.ReadToEnd()

# Publish the payload for the Claude Usage Monitor to read.
# Temp file + rename so a reader never catches a half-written document.
try {
    $usagePath = Join-Path $HOME '.claude\usage-input.json'
    [System.IO.File]::WriteAllText("$usagePath.tmp", $inputJson, $utf8)
    Move-Item -LiteralPath "$usagePath.tmp" -Destination $usagePath -Force
}
catch {
}

try {
    $payload = $inputJson | ConvertFrom-Json
}
catch {
    $payload = $null
}

# Walk a dotted property path, returning $Default when any segment is absent.
# Like jq's `//`, null and false both count as absent.
function Get-Field {
    param(
        [string] $Path,
        $Default = $null
    )

    $node = $payload
    foreach ($name in $Path.Split('.')) {
        if ($null -eq $node -or -not $node.PSObject.Properties[$name]) {
            return $Default
        }
        $node = $node.$name
    }

    if ($null -eq $node -or $node -is [bool] -and -not $node) { $Default } else { $node }
}

# Read a numeric field; absent or non-numeric values yield $Default.
function Get-Number {
    param(
        [string] $Path,
        $Default = $null
    )

    $value = Get-Field $Path
    if ($value -is [ValueType] -and $value -isnot [bool] -and $value -isnot [datetime]) {
        return [double] $value
    }

    $number = 0.0
    if ($value -is [string] -and [double]::TryParse($value, 'Float', $invariant, [ref] $number)) {
        return $number
    }
    $Default
}

# Only a literal true enables a flag, as in the original `[ "$x" = "true" ]` tests.
function Test-Flag([string] $Path) {
    [string] (Get-Field $Path) -eq 'true'
}

$esc = [char] 27
$reset = "$esc[0m"
$muted = "$esc[38;5;244m" # secondary text
$dim = "$esc[38;5;240m"   # tertiary text — tree glyphs, separators
$cyan = "$esc[38;5;51m"
$sep = "$dim│$reset"
$barWidth = 10

# Round a percentage half away from zero.
function ConvertTo-Rounded([double] $Value) {
    [int] [Math]::Round($Value, [MidpointRounding]::AwayFromZero)
}

# Pick a color from a used-percentage: green < 50, yellow < 80, red otherwise.
function Get-SeverityColor([double] $Used) {
    if ($Used -ge 80) { "$esc[01;38;5;196m" }
    elseif ($Used -ge 50) { "$esc[01;38;5;220m" }
    else { "$esc[01;38;5;77m" }
}

# Fixed-point text that rounds exact midpoints to even, as printf does.
function Format-Fixed([double] $Value, [int] $Digits) {
    [Math]::Round($Value, $Digits, [MidpointRounding]::ToEven).ToString("F$Digits", $invariant)
}

# Human-readable token count (e.g. 16.7k, 1.2M).
function Format-TokenCount([double] $Count) {
    if ($Count -ge 1000000) { (Format-Fixed ($Count / 1000000) 1) + 'M' }
    elseif ($Count -ge 1000) { (Format-Fixed ($Count / 1000) 1) + 'k' }
    else { ([long] [Math]::Truncate($Count)).ToString($invariant) }
}

# Time-until from a unix epoch (e.g. 3d4h, 1h02m, 5m, now).
function Format-Countdown([long] $Epoch) {
    $seconds = $Epoch - [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    if ($seconds -lt 0) { return 'now' }

    $span = [TimeSpan]::FromSeconds($seconds)
    if ($span.Days -gt 0) { '{0}d{1}h' -f $span.Days, $span.Hours }
    elseif ($span.Hours -gt 0) { '{0}h{1:00}m' -f $span.Hours, $span.Minutes }
    else { '{0}m' -f $span.Minutes }
}

function Get-FilledCount([double] $Used, [int] $Width) {
    [Math]::Clamp((ConvertTo-Rounded ($Width * $Used / 100)), 0, $Width)
}

# Filled bar whose colour ramps green → red across the filled span.
function Format-GradientBar([double] $Used, [int] $Width) {
    $palette = 77, 113, 149, 185, 221, 220, 214, 208, 202, 196
    $filled = Get-FilledCount $Used $Width
    $bar = [System.Text.StringBuilder]::new()
    for ($i = 0; $i -lt $Width; $i++) {
        if ($i -lt $filled) {
            $index = if ($Width -gt 1) { [int] [Math]::Floor($i * 9 / ($Width - 1)) } else { 9 }
            [void] $bar.Append("$esc[38;5;$($palette[$index])m█")
        }
        else {
            [void] $bar.Append("$esc[38;5;236m█")
        }
    }
    $bar.ToString() + $reset
}

# Flat bar in a single severity colour.
function Format-SolidBar([double] $Used, [int] $Width) {
    $filled = Get-FilledCount $Used $Width
    (Get-SeverityColor $Used) + ('█' * $filled) + "$esc[38;5;236m" + ('█' * ($Width - $filled)) + $reset
}

$model = Get-Field 'model.display_name' '?'
$effort = [string] (Get-Field 'effort.level' '')
$contextUsed = Get-Number 'context_window.used_percentage' 0
$tokens = (Get-Number 'context_window.total_input_tokens' 0) + (Get-Number 'context_window.total_output_tokens' 0)
$contextSize = Get-Number 'context_window.context_window_size' 200000
$cost = Get-Number 'cost.total_cost_usd' 0
$fast = Test-Flag 'fast_mode'
$thinking = Test-Flag 'thinking.enabled'
$style = [string] (Get-Field 'output_style.name' 'default')

# --- Line 1: context, model, cost ---
$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { '.' }
$branch = try { git -C $projectDir rev-parse --abbrev-ref HEAD 2>$null } catch { $null }
if ([string]::IsNullOrEmpty($branch)) { $branch = $style }

$contextRounded = ConvertTo-Rounded $contextUsed
$line = "$cyan$branch$reset $sep $model"
if ($effort) { $line += " $muted$effort$reset" }
$line += " $sep 🔥 $(Format-GradientBar $contextRounded $barWidth) $(Get-SeverityColor $contextRounded)$contextRounded%$reset"
$line += " $sep $muted$(Format-TokenCount $tokens)/$(Format-TokenCount $contextSize)$reset"
$line += " $sep `$$(Format-Fixed $cost 2)"
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add($line)

# --- Rate-limit rows (Pro/Max only) ---
function Format-LimitRow([string] $Glyph, [string] $Label, [string] $Window) {
    $used = Get-Number "rate_limits.$Window.used_percentage"
    if ($null -eq $used) { return $null }

    $rounded = ConvertTo-Rounded $used
    $row = "$dim$Glyph$reset $muted$Label$reset $(Format-SolidBar $rounded $barWidth) " +
        "$(Get-SeverityColor $used)$('{0,3}' -f $rounded)%$reset"
    $resetsAt = Get-Number "rate_limits.$Window.resets_at"
    if ($null -ne $resetsAt) { $row += "  $dim↺ $(Format-Countdown ([long] [Math]::Floor($resetsAt)))$reset" }
    $row
}

foreach ($row in (Format-LimitRow '├' '5h' 'five_hour'), (Format-LimitRow '└' '7d' 'seven_day')) {
    if ($row) { $lines.Add($row) }
}

# --- Mode flags — only shown when off the defaults ---
$flags = @()
if ($fast) { $flags += '⚡fast' }
if (-not $thinking) { $flags += '💤thinking off' }
if ($style -ne 'default') { $flags += "🎨$style" }
if ($flags) { $lines.Add($muted + ($flags -join ' ') + $reset) }

[Console]::Out.Write($lines -join "`n")
