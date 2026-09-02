[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'This branch and bootstrap script support native Windows only.'
}

if ($PSVersionTable.PSEdition -ne 'Core' -or $PSVersionTable.PSVersion -lt [Version]'7.0') {
    throw 'PowerShell 7.0 or newer is required. Run bootstrap.ps1 with pwsh.exe.'
}

$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($currentPolicy -notin @('RemoteSigned', 'Unrestricted', 'Bypass')) {
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
}

$effectivePolicy = Get-ExecutionPolicy
if ($effectivePolicy -notin @('RemoteSigned', 'Unrestricted', 'Bypass')) {
    throw "The effective PowerShell execution policy is '$effectivePolicy'. Local dotfiles scripts must be allowed to run."
}

$developerModePath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
$developerMode = if (Test-Path -LiteralPath $developerModePath) {
    (Get-ItemProperty -LiteralPath $developerModePath -Name AllowDevelopmentWithoutDevLicense -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
}

if ($developerMode -ne 1) {
    throw 'Windows Developer Mode is required for managed symlinks. Enable Settings > System > Advanced > For developers, then rerun bootstrap.ps1.'
}

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host 'Installing Scoop...'
    $scoopInstaller = Invoke-RestMethod -Uri 'https://get.scoop.sh'
    Invoke-Expression $scoopInstaller
}

& (Join-Path $PSScriptRoot 'scripts\install-packages.ps1')
& (Join-Path $PSScriptRoot 'scripts\link-dotfiles.ps1')
& (Join-Path $PSScriptRoot 'scripts\update-skills.ps1')
& (Join-Path $PSScriptRoot 'scripts\verify-system.ps1')

Write-Host 'Windows developer environment bootstrap complete.'
