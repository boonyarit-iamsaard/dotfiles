[CmdletBinding()]
param(
    [switch] $Check
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$dotfilesRoot = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $dotfilesRoot 'manifests\node-toolchain.json'
$packagePath = Join-Path $dotfilesRoot 'package.json'
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
$package = Get-Content -Raw -LiteralPath $packagePath | ConvertFrom-Json
$nodeRelease = [string] $manifest.nodeRelease
$nvmMode = [string] $manifest.nvmMode
$packageManager = [string] $package.packageManager

if ($nodeRelease -notmatch '^\d+$') {
    throw "Invalid Node.js release in ${manifestPath}: '$nodeRelease'"
}
if ($nvmMode -notin @('link', 'shim')) {
    throw "Invalid NVM mode in ${manifestPath}: '$nvmMode'"
}
if ($packageManager -notmatch '^pnpm@(?<version>\d+\.\d+\.\d+)$') {
    throw "Expected package.json packageManager to pin pnpm; found '$packageManager'."
}
$pnpmVersion = $Matches.version

if (-not (Get-Command nvm -ErrorAction SilentlyContinue)) {
    throw 'NVM is not available. Install the manifest-declared Scoop packages first.'
}

function Invoke-CheckedCommand {
    param(
        [Parameter(Mandatory)] [string] $Command,
        [Parameter(Mandatory)] [string[]] $Arguments
    )

    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed: $Command $($Arguments -join ' ')"
    }
}

function Get-CommandOutput {
    param(
        [Parameter(Mandatory)] [string] $Command,
        [string[]] $Arguments = @()
    )

    $output = (& $Command @Arguments 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed: $Command $($Arguments -join ' ')`n$output"
    }
    return $output
}

if (-not $Check) {
    $currentMode = Get-CommandOutput -Command 'nvm' -Arguments @('config', 'get', 'mode')
    if ($currentMode -ne $nvmMode) {
        Invoke-CheckedCommand -Command 'nvm' -Arguments @('config', 'set', "mode=$nvmMode")
    }

    Invoke-CheckedCommand -Command 'nvm' -Arguments @('install', $nodeRelease)
    Invoke-CheckedCommand -Command 'nvm' -Arguments @('use', $nodeRelease)
    Invoke-CheckedCommand -Command 'corepack' -Arguments @('enable')
    Invoke-CheckedCommand -Command 'nvm' -Arguments @('reshim')
}

$actualMode = Get-CommandOutput -Command 'nvm' -Arguments @('config', 'get', 'mode')
if ($actualMode -ne $nvmMode) {
    throw "NVM mode drift: expected '$nvmMode', found '$actualMode'."
}

$actualNodeVersion = Get-CommandOutput -Command 'node' -Arguments @('--version')
if ($actualNodeVersion -notmatch "^v$([regex]::Escape($nodeRelease))\.") {
    throw "Node.js release drift: expected '$nodeRelease.x', found '$actualNodeVersion'."
}

$null = Get-CommandOutput -Command 'corepack' -Arguments @('--version')
Push-Location $dotfilesRoot
try {
    $actualPnpmVersion = Get-CommandOutput -Command 'pnpm' -Arguments @('--version')
}
finally {
    Pop-Location
}
if ($actualPnpmVersion -ne $pnpmVersion) {
    throw "pnpm version drift: expected '$pnpmVersion', found '$actualPnpmVersion'."
}

Write-Host "Node toolchain verified: Node.js $actualNodeVersion, pnpm $pnpmVersion, NVM $nvmMode mode."
