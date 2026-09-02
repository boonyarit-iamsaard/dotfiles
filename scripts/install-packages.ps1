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

$configuredBuckets = @(scoop bucket list | ForEach-Object { $_.Name })
foreach ($bucket in $manifest.scoop.buckets) {
    if ($bucket -notin $configuredBuckets) {
        Write-Host "Adding Scoop bucket: $bucket"
        scoop bucket add $bucket
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to add Scoop bucket: $bucket"
        }
    }
}

foreach ($package in $manifest.scoop.packages) {
    $null = scoop prefix $package 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Already installed: $package"
        continue
    }

    Write-Host "Installing: $package"
    scoop install $package
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install Scoop package: $package"
    }
}
