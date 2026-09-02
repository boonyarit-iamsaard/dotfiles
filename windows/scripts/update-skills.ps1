[CmdletBinding()]
param(
    [switch] $DryRun,
    [switch] $Check,
    [switch] $Migrate,
    [switch] $NoPull
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSEdition -ne 'Core' -or $PSVersionTable.PSVersion -lt [Version]'7.0') {
    throw 'PowerShell 7.0 or newer is required. Run this script with pwsh.exe.'
}

$dotfilesRoot = if ($env:DOTFILES_ROOT) {
    [IO.Path]::GetFullPath($env:DOTFILES_ROOT)
}
else {
    Split-Path -Parent $PSScriptRoot
}
$manifest = Get-Content -Raw -LiteralPath (Join-Path $dotfilesRoot 'manifests\skills.json') | ConvertFrom-Json
$userHome = if ($env:SKILL_SYNC_HOME) {
    [IO.Path]::GetFullPath($env:SKILL_SYNC_HOME)
}
else {
    [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
}
$skillsRepository = if ($env:SKILLS_REPO) {
    [IO.Path]::GetFullPath($env:SKILLS_REPO)
}
else {
    $checkout = ([string] $manifest.repository.checkout).Replace('{home}', $userHome)
    [IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables($checkout))
}
$stateRoot = if ($env:SKILL_SYNC_STATE_ROOT) {
    [IO.Path]::GetFullPath($env:SKILL_SYNC_STATE_ROOT)
}
else {
    Join-Path $env:LOCALAPPDATA 'dotfiles\skill-sync'
}
$backupRoot = if ($env:SKILL_SYNC_BACKUP_ROOT) {
    [IO.Path]::GetFullPath($env:SKILL_SYNC_BACKUP_ROOT)
}
else {
    Join-Path $stateRoot 'backups'
}

$configuration = [pscustomobject]@{
    DotfilesRoot = $dotfilesRoot
    Manifest = $manifest
    UserHome = $userHome
    SkillsRepository = $skillsRepository
    StatePath = Join-Path $stateRoot 'managed-links.json'
    BackupRoot = $backupRoot
}

Import-Module (Join-Path $PSScriptRoot 'modules\SkillSynchronization.psm1') -Force
$result = Invoke-SkillSynchronization -Configuration $configuration -DryRun:$DryRun -Check:$Check -Migrate:$Migrate -NoPull:$NoPull

foreach ($message in $result.Messages) {
    Write-Host $message
}
if ($result.Actions.Count -eq 0) {
    Write-Host 'Skills already up to date.'
}
else {
    foreach ($action in $result.Actions) {
        Write-Host "$($action.Kind): $($action.Consumer)/$($action.Name)"
    }
}
if ($result.BackupDirectory) {
    Write-Host "Backup: $($result.BackupDirectory)"
}
if ($result.Synchronized) {
    Write-Host 'Skills synchronized.'
}

exit $result.ExitCode
