# PowerShell 7 profile.
#
# Managed by the dotfiles repository. The real file lives in
# dotfiles\powershell and is symlinked to $PROFILE by
# scripts\link-dotfiles.ps1, so $PSScriptRoot below resolves to
# Documents\PowerShell either way.

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------
# NVM places the active Node directory before Scoop's shims. Prefer Scoop so
# standalone tools such as pnpm are not shadowed by Node's Corepack shims.
$scoopRoot = if ($env:SCOOP) {
    $env:SCOOP
}
else {
    Join-Path ([Environment]::GetFolderPath('UserProfile')) 'scoop'
}
$scoopShims = Join-Path $scoopRoot 'shims'

$preferredPathEntries = @(
    if (Test-Path -LiteralPath $scoopShims -PathType Container) {
        $scoopShims
    }
)

$androidSdkRoot = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
if (Test-Path -LiteralPath $androidSdkRoot -PathType Container) {
    $env:ANDROID_HOME = $androidSdkRoot
    # ANDROID_SDK_ROOT is deprecated, but some existing tools still read it.
    $env:ANDROID_SDK_ROOT = $androidSdkRoot

    $preferredPathEntries += @(
        'platform-tools'
        'emulator'
        'cmdline-tools\latest\bin'
    ) | ForEach-Object { Join-Path $androidSdkRoot $_ } | Where-Object {
        Test-Path -LiteralPath $_ -PathType Container
    }
}

if ($preferredPathEntries) {
    $normalizedPreferredEntries = @($preferredPathEntries | ForEach-Object { $_.TrimEnd('\') })
    $pathEntries = @($env:Path -split ';' | Where-Object {
            $_ -and $_.TrimEnd('\') -notin $normalizedPreferredEntries
        })
    $env:Path = (@($preferredPathEntries) + $pathEntries) -join ';'
}

# ---------------------------------------------------------------------------
# Prompt
# ---------------------------------------------------------------------------
# Oh My Posh renders the prompt with Starship's Nerd Font Symbols preset style.
$ompTheme = Join-Path $PSScriptRoot 'oh-my-posh\nerd-font-symbols.omp.json'
$ompCommand = Get-Command oh-my-posh -ErrorAction SilentlyContinue

if ($ompCommand) {
    & $ompCommand.Source init pwsh --config $ompTheme | Invoke-Expression
}
else {
    Write-Warning 'Oh My Posh was not found on PATH. Reopen the terminal after installing it.'
}

# ---------------------------------------------------------------------------
# Modules
# ---------------------------------------------------------------------------
# Terminal-Icons comes from the PowerShell Gallery, not Scoop:
#   Install-Module Terminal-Icons -Scope CurrentUser
if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module -Name Terminal-Icons
}

Import-Module PSReadLine

# ---------------------------------------------------------------------------
# Line editing
# ---------------------------------------------------------------------------
# Some embedded console hosts report interactivity without supporting
# PSReadLine rendering, hence the guard and the try block.
if ($Host.Name -eq 'ConsoleHost' -and -not [Console]::IsOutputRedirected) {
    try {
        Set-PSReadLineOption -PredictionSource History -ErrorAction Stop
        Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction Stop
    }
    catch {
        # Leave PSReadLine at its defaults when the host cannot support these.
    }
}

# ---------------------------------------------------------------------------
# Aliases
# ---------------------------------------------------------------------------
Set-Alias -Name lzg -Value lazygit

# ---------------------------------------------------------------------------
# Dotfiles scripts
# ---------------------------------------------------------------------------
# Alias the scripts that are run by hand, under the same names the README
# uses. This file is symlinked into the repository, so the link target locates
# the checkout without a hard-coded path.
$profileItem = Get-Item -LiteralPath $PROFILE -Force -ErrorAction SilentlyContinue
$profileTarget = if ($profileItem) { @($profileItem.Target)[0] }

if ($profileTarget) {
    $dotfilesRoot = Split-Path (Split-Path $profileTarget -Parent) -Parent

    foreach ($script in 'link-dotfiles', 'update-skills', 'update-system', 'verify-system') {
        $scriptPath = Join-Path $dotfilesRoot "scripts\$script.ps1"
        if (Test-Path -LiteralPath $scriptPath -PathType Leaf) {
            Set-Alias -Name $script -Value $scriptPath -Scope Global
        }
    }
}
