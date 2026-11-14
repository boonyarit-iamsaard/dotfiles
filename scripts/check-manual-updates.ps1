[CmdletBinding()]
param()

# Reports updates that need a deliberate manual step. Read-only: it fetches
# the skills checkout but never pulls, and it never changes vendored payloads.
# Network failures are reported per row and never fail the script.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSEdition -ne 'Core' -or $PSVersionTable.PSVersion -lt [Version]'7.0') {
    throw 'PowerShell 7.0 or newer is required. Run this script with pwsh.exe.'
}

$dotfilesRoot = Split-Path -Parent $PSScriptRoot
$manifest = Get-Content -Raw -LiteralPath (Join-Path $dotfilesRoot 'manifests\skills.json') | ConvertFrom-Json
$rows = [System.Collections.Generic.List[object]]::new()

function Add-Row([string] $Name, [string] $Status, [string] $Action) {
    $rows.Add([pscustomobject]@{ Name = $Name; Status = $Status; Action = $Action })
}

# Upstream skills checkout: fetch only, then count commits behind upstream.
$checkout = ([string] $manifest.repository.checkout).Replace('{home}', [Environment]::GetFolderPath('UserProfile'))
if (-not (Test-Path -LiteralPath (Join-Path $checkout '.git'))) {
    Add-Row 'skills' "no checkout at $checkout" 'run update-skills'
}
else {
    git -C $checkout fetch --quiet 2>$null
    $behind = if ($LASTEXITCODE -eq 0) { git -C $checkout rev-list --count 'HEAD..@{u}' 2>$null }
    if ($LASTEXITCODE -ne 0 -or -not $behind) {
        Add-Row 'skills' "couldn't check" ''
    }
    elseif ([int] $behind -gt 0) {
        Add-Row 'skills' "$checkout is $behind commit(s) behind upstream" 'run update-skills'
    }
}

foreach ($entry in $manifest.vendor.PSObject.Properties) {
    $name = $entry.Name
    $vendor = $entry.Value
    $action = "see $($vendor.doc)"

    if ($vendor.PSObject.Properties['npm']) {
        $latest = npm view $vendor.npm version 2>$null
        if ($LASTEXITCODE -ne 0 -or -not $latest) {
            Add-Row $name "couldn't check" ''
            continue
        }
        $latest = ([string] $latest).Trim()
        $latestVersion = $null
        $vendoredVersion = $null
        $newer = if ([semver]::TryParse($latest, [ref] $latestVersion) -and
            [semver]::TryParse($vendor.version, [ref] $vendoredVersion)) {
            $latestVersion -gt $vendoredVersion
        }
        else {
            $latest -ne $vendor.version
        }
        if ($newer) {
            Add-Row $name "vendored $($vendor.version), npm has $latest" $action
        }
    }
    elseif ($vendor.PSObject.Properties['git']) {
        $line = git ls-remote $vendor.git "refs/heads/$($vendor.branch)" 2>$null
        if ($LASTEXITCODE -ne 0 -or -not $line) {
            Add-Row $name "couldn't check" ''
            continue
        }
        $head = (([string] @($line)[0]) -split '\s+')[0]
        if ($head -ne $vendor.commit) {
            Add-Row $name "vendored $($vendor.commit.Substring(0, 7)), upstream at $($head.Substring(0, 7))" $action
        }
    }
    else {
        Add-Row $name 'unknown vendor source in manifests\skills.json' ''
    }
}

if ($rows.Count -eq 0) {
    Write-Host 'Manual follow-up: nothing to do.'
    exit 0
}

Write-Host 'Manual follow-up:'
$width = ($rows.Name | Measure-Object -Property Length -Maximum).Maximum
foreach ($row in $rows) {
    $text = "  {0}  {1}" -f $row.Name.PadRight($width), $row.Status
    if ($row.Action) { $text += "  -> $($row.Action)" }
    Write-Host $text
}

# A failed git or npm probe is a report row, not a script failure.
exit 0
