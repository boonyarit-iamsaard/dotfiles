[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSEdition -ne 'Core' -or $PSVersionTable.PSVersion -lt [Version]'7.0') {
    throw 'PowerShell 7.0 or newer is required. Run this script with pwsh.exe.'
}

$dotfilesRoot = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $dotfilesRoot 'manifests\packages.json'
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    throw 'Scoop is not installed. Run bootstrap.ps1 first.'
}

Write-Host 'Updating Scoop and configured buckets...'
scoop update
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to update Scoop or its buckets.'
}

foreach ($package in $manifest.scoop.packages) {
    $null = scoop prefix $package 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Skipping package not installed by Scoop: $package"
        continue
    }

    Write-Host "Updating developer package: $package"
    scoop update $package
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to update Scoop package: $package"
    }

    scoop cleanup --cache $package
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to clean old Scoop versions and downloads for: $package"
    }
}

# Reapply the declared Node.js version and Corepack shims after NVM upgrades.
& (Join-Path $PSScriptRoot 'set-node-toolchain.ps1')

# Scoop package upgrades (nvm, temurin*-jdk) rewrite the user Path and
# JAVA_HOME. Reapply the manifest so the managed entries stay authoritative.
& (Join-Path $PSScriptRoot 'set-environment.ps1')

Write-Host 'Developer environment update complete.'
