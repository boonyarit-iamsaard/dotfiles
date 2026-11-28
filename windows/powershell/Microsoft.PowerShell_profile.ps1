# PowerShell 7 profile.
#
# Managed by the dotfiles repository. The real file lives in
# dotfiles\windows\powershell and is symlinked to $PROFILE by
# windows\scripts\link-dotfiles.ps1, so $PSScriptRoot below resolves to
# Documents\PowerShell either way.

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------
# NVM places the active Node directory before Scoop's shims. Prefer Scoop for
# declared standalone tools; pnpm is intentionally provided by Node's Corepack
# shim so projects can select their package-manager version. The gh-agent
# wrappers must stay ahead of Scoop's gh shim, so they lead.
$scoopRoot = if ($env:SCOOP) {
    $env:SCOOP
}
else {
    Join-Path ([Environment]::GetFolderPath('UserProfile')) 'scoop'
}
$scoopShims = Join-Path $scoopRoot 'shims'
$ghAgentBin = Join-Path ([Environment]::GetFolderPath('UserProfile')) 'dotfiles\windows\gh-agent\bin'

$preferredPathEntries = @(
    foreach ($entry in $ghAgentBin, $scoopShims) {
        if (Test-Path -LiteralPath $entry -PathType Container) {
            $entry
        }
    }
)

if ($preferredPathEntries) {
    $normalizedPreferredEntries = @($preferredPathEntries | ForEach-Object { $_.TrimEnd('\') })
    $pathEntries = @($env:Path -split ';' | Where-Object {
            $_ -and $_.TrimEnd('\') -notin $normalizedPreferredEntries
        })
    $env:Path = (@($preferredPathEntries) + $pathEntries) -join ';'
}

function Set-JavaVersion {
    param([Parameter(Mandatory)] [ValidateSet(17, 25)] [int] $MajorVersion)

    $javaHome = Join-Path $scoopRoot "apps\temurin$MajorVersion-jdk\current"
    if (-not (Test-Path -LiteralPath $javaHome -PathType Container)) {
        throw "Temurin $MajorVersion is not installed by Scoop."
    }

    $javaBin = Join-Path $javaHome 'bin'
    $managedJavaBins = @('17', '25' | ForEach-Object {
            (Join-Path $scoopRoot "apps\temurin$_-jdk\current\bin").TrimEnd('\')
        })
    $pathEntries = @($env:Path -split ';' | Where-Object {
            $_ -and $_.TrimEnd('\') -notin $managedJavaBins
        })

    $env:JAVA_HOME = $javaHome
    $env:Path = (@($javaBin) + $pathEntries) -join ';'
    Write-Host "Using Temurin $MajorVersion in this PowerShell session."
}

function jdk17 { Set-JavaVersion -MajorVersion 17 }
function jdk25 { Set-JavaVersion -MajorVersion 25 }

# ---------------------------------------------------------------------------
# Prompt
# ---------------------------------------------------------------------------
# This file is symlinked into the platform folder, so the link target locates
# the checkout without a hard-coded path.
$profileItem = Get-Item -LiteralPath $PROFILE -Force -ErrorAction SilentlyContinue
$profileTarget = if ($profileItem) { @($profileItem.Target)[0] }
$profileDir = if ($profileTarget) { Split-Path $profileTarget -Parent } else { $PSScriptRoot }
$platformRoot = Split-Path $profileDir -Parent
$checkoutRoot = Split-Path $platformRoot -Parent

# Oh My Posh and LazyGit follow this machine's active theme, saved by set-theme.
Import-Module (Join-Path $platformRoot 'scripts\modules\ActiveTheme.psm1')
$activeTheme = try { Get-ActiveTheme } catch { Write-Warning $_; Get-DefaultTheme }
$ompTheme = Join-Path $profileDir "oh-my-posh\$activeTheme.omp.json"
if (-not (Test-Path -LiteralPath $ompTheme -PathType Leaf)) {
    Write-Warning "Theme '$activeTheme' has no Oh My Posh prompt; using the default theme. Run set-theme -List."
    $activeTheme = Get-DefaultTheme
    $ompTheme = Join-Path $profileDir "oh-my-posh\$activeTheme.omp.json"
}
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
Set-Alias -Name lzd -Value lazydocker

# ---------------------------------------------------------------------------
# Dotfiles scripts
# ---------------------------------------------------------------------------
# Alias the scripts that are run by hand, under the same names the README
# uses.
if ($profileTarget) {
    # LazyGit reads the shared base first, then the active theme's variant.
    $env:LG_CONFIG_FILE = @(
        Join-Path $checkoutRoot 'shared\config\lazygit\config.yml'
        Join-Path $checkoutRoot "shared\themes\lazygit\$activeTheme.yml"
    ) -join ','

    foreach ($script in 'check-manual-updates', 'docker-cleanup', 'link-dotfiles', 'set-environment', 'set-theme', 'update-skills', 'update-system', 'verify-system') {
        $scriptPath = Join-Path $platformRoot "scripts\$script.ps1"
        if (Test-Path -LiteralPath $scriptPath -PathType Leaf) {
            Set-Alias -Name $script -Value $scriptPath -Scope Global
        }
    }
}
