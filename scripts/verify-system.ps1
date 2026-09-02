[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$dotfilesRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $PSScriptRoot 'modules\ManagedWindowsLinks.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'modules\SkillInventory.psm1') -Force

$packageManifest = Get-Content -Raw -LiteralPath (Join-Path $dotfilesRoot 'manifests\packages.json') | ConvertFrom-Json
$linkManifest = Get-Content -Raw -LiteralPath (Join-Path $dotfilesRoot 'manifests\links.json') | ConvertFrom-Json
$skillManifest = Get-Content -Raw -LiteralPath (Join-Path $dotfilesRoot 'manifests\skills.json') | ConvertFrom-Json
$failures = [Collections.Generic.List[string]]::new()

$runningOnWindows = [Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT
if (-not $runningOnWindows) {
    $failures.Add('This branch supports native Windows only.')
}

if ($PSVersionTable.PSEdition -ne 'Core' -or $PSVersionTable.PSVersion -lt [Version]'7.0') {
    $failures.Add("PowerShell 7.0 or newer is required; found $($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion).")
}

$effectivePolicy = Get-ExecutionPolicy
if ($effectivePolicy -notin @('RemoteSigned', 'Unrestricted', 'Bypass')) {
    $failures.Add("PowerShell execution policy does not allow local scripts: $effectivePolicy")
}

$developerModePath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
$developerMode = if (Test-Path -LiteralPath $developerModePath) {
    (Get-ItemProperty -LiteralPath $developerModePath -Name AllowDevelopmentWithoutDevLicense -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
}
if ($developerMode -ne 1) {
    $failures.Add('Windows Developer Mode is not enabled.')
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    $failures.Add('Git is not available.')
}
else {
    $branch = git -C $dotfilesRoot branch --show-current
    if ($LASTEXITCODE -ne 0) {
        $failures.Add('The dotfiles directory is not a valid Git checkout.')
    }
    elseif ($branch -ne 'windows') {
        $failures.Add("Expected the windows branch; found '$branch'.")
    }
}

$scoopAvailable = $null -ne (Get-Command scoop -ErrorAction SilentlyContinue)
if (-not $scoopAvailable) {
    $failures.Add('Scoop is not available.')
}

foreach ($package in $packageManifest.scoop.packages) {
    if ($scoopAvailable) {
        $null = scoop prefix $package 2>$null
        if ($LASTEXITCODE -ne 0) {
            $failures.Add("Package is not installed by Scoop: $package")
        }
    }

    if (-not (Get-Command $package -ErrorAction SilentlyContinue)) {
        $failures.Add("Command is not available: $package")
    }
}

foreach ($packageName in $linkManifest.PSObject.Properties.Name) {
    foreach ($mapping in $linkManifest.$packageName) {
        $source = [IO.Path]::GetFullPath((Join-Path $dotfilesRoot $mapping.source))
        $target = [Environment]::ExpandEnvironmentVariables($mapping.target)
        if (-not (Get-ManagedLinkTarget -Path $target)) {
            $failures.Add("Missing managed symlink: $target")
            continue
        }
        if (-not (Test-ManagedLink -Path $target -Source $source)) {
            $failures.Add("Symlink has the wrong target: $target")
        }
    }
}

$userHome = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
$checkout = ([string] $skillManifest.repository.checkout).Replace('{home}', $userHome)
$skillsRepository = [IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables($checkout))
if (-not (Test-Path -LiteralPath (Join-Path $skillsRepository '.git') -PathType Container)) {
    $failures.Add("Skills checkout is missing or is not a Git repository: $skillsRepository")
}
else {
    try {
        $inventory = Get-SkillInventory -Manifest $skillManifest -DotfilesRoot $dotfilesRoot `
            -SkillsRepository $skillsRepository -UserHome $userHome
        foreach ($skill in $inventory.Skills.Values) {
            if (-not (Get-ManagedLinkTarget -Path $skill.Target)) {
                $failures.Add("Missing managed skill symlink: $($skill.Target)")
                continue
            }
            if (-not (Test-ManagedLink -Path $skill.Target -Source $skill.Source)) {
                $failures.Add("Skill symlink has the wrong target: $($skill.Target)")
            }
        }
    }
    catch {
        $failures.Add($_.Exception.Message)
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Host 'Developer environment verification passed.'
