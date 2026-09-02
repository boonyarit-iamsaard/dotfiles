[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSEdition -ne 'Core' -or $PSVersionTable.PSVersion -lt [Version]'7.0') {
    throw 'PowerShell 7.0 or newer is required. Run this script with pwsh.exe.'
}

$updater = Join-Path $PSScriptRoot 'update-skills.ps1'
Import-Module (Join-Path $PSScriptRoot 'modules\SkillSynchronization.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'modules\ManagedWindowsLinks.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'modules\SkillInventory.psm1') -Force

$testRoot = Join-Path ([IO.Path]::GetTempPath()) ("dotfiles-skill-test-" + [Guid]::NewGuid().ToString('N'))
$dotfiles = Join-Path $testRoot 'dotfiles'
$repository = Join-Path $testRoot 'skills'
$testHome = Join-Path $testRoot 'home'
$state = Join-Path $testRoot 'state'
$backups = Join-Path $testRoot 'backups'

function Assert-True {
    param(
        [Parameter(Mandatory)] [bool] $Condition,
        [Parameter(Mandatory)] [string] $Message
    )

    if (-not $Condition) {
        throw "Assertion failed: $Message"
    }
}

function Invoke-TestGit {
    param([Parameter(Mandatory)] [string[]] $Arguments)

    $previousErrorPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& git -c "safe.directory=$repository" @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorPreference
    }
    if ($exitCode -ne 0) {
        throw "git $($Arguments -join ' ') failed:`n$($output -join [Environment]::NewLine)"
    }
}

function Invoke-Updater {
    param(
        [Parameter(Mandatory)] [string[]] $Arguments,
        [Parameter(Mandatory)] [int] $ExpectedExitCode
    )

    $previousErrorPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& pwsh.exe -NoProfile -ExecutionPolicy Bypass -File $updater @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorPreference
    }
    if ($exitCode -ne $ExpectedExitCode) {
        throw "Updater exited $exitCode; expected $ExpectedExitCode.`n$($output -join [Environment]::NewLine)"
    }
    return $output
}

function Invoke-Core {
    param(
        [Parameter(Mandatory)] [int] $ExpectedExitCode,
        [switch] $Check,
        [switch] $Migrate
    )

    $manifest = Get-Content -Raw -LiteralPath (Join-Path $dotfiles 'manifests\skills.json') | ConvertFrom-Json
    $configuration = [pscustomobject]@{
        DotfilesRoot = $dotfiles
        Manifest = $manifest
        UserHome = $testHome
        SkillsRepository = $repository
        StatePath = Join-Path $state 'managed-links.json'
        BackupRoot = $backups
    }
    $result = Invoke-SkillSynchronization -Configuration $configuration -Check:$Check -Migrate:$Migrate -NoPull
    Assert-True ($result.ExitCode -eq $ExpectedExitCode) "core exited $($result.ExitCode); expected $ExpectedExitCode"
    return $result
}

function Assert-LinkTarget {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $Expected
    )

    Assert-True (Test-ManagedLink -Path $Path -Source $Expected) "$Path is not linked to $Expected"
}

try {
    New-Item -ItemType Directory -Force -Path (Join-Path $dotfiles 'manifests') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $dotfiles 'skills\shared\local-one') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $repository 'skills\engineering\alpha') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $repository 'skills\productivity') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $testHome '.claude\skills') | Out-Null

    @'
# Engineering
'@ | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $repository 'skills\engineering\README.md')
    @'
# Productivity
'@ | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $repository 'skills\productivity\README.md')
    @'
---
name: alpha
description: Test alpha.
---

Alpha.
'@ | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $repository 'skills\engineering\alpha\SKILL.md')
    @'
---
name: local-one
description: Test local skill.
---

Local.
'@ | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $dotfiles 'skills\shared\local-one\SKILL.md')

    Invoke-TestGit @('-C', $repository, 'init')
    Invoke-TestGit @('-C', $repository, 'config', 'user.name', 'Skill Test')
    Invoke-TestGit @('-C', $repository, 'config', 'user.email', 'skill-test@example.invalid')
    Invoke-TestGit @('-C', $repository, 'add', '.')
    Invoke-TestGit @('-C', $repository, 'commit', '-m', 'initial skills')

    @'
{
  "version": 1,
  "repository": {
    "url": "https://example.invalid/skills.git",
    "checkout": "{home}\\skills",
    "categories": ["engineering", "productivity"]
  },
  "consumers": {
    "codex": { "target": "{home}\\.agents\\skills" },
    "claude": { "target": "{home}\\.claude\\skills" }
  },
  "localSkills": [
    {
      "name": "local-one",
      "source": "skills\\shared\\local-one",
      "consumers": ["codex", "claude"]
    }
  ]
}
'@ | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $dotfiles 'manifests\skills.json')

    Copy-Item -Recurse -LiteralPath (Join-Path $repository 'skills\engineering\alpha') -Destination (Join-Path $testHome '.claude\skills\alpha')

    $env:DOTFILES_ROOT = $dotfiles
    $env:SKILLS_REPO = $repository
    $env:SKILL_SYNC_HOME = $testHome
    $env:SKILL_SYNC_STATE_ROOT = $state
    $env:SKILL_SYNC_BACKUP_ROOT = $backups

    $manifest = Get-Content -Raw -LiteralPath (Join-Path $dotfiles 'manifests\skills.json') | ConvertFrom-Json
    $inventory = Get-SkillInventory -Manifest $manifest -DotfilesRoot $dotfiles `
        -SkillsRepository $repository -UserHome $testHome
    Assert-True ($inventory.Skills.Count -eq 4) 'inventory did not produce every consumer/skill pair'
    Assert-True ($inventory.Skills['codex/local-one'].Provenance -eq 'local') 'inventory lost local skill provenance'
    Assert-True (
        (Test-PathEquivalent -Left $inventory.Skills['claude/alpha'].Target -Right (Join-Path $testHome '.claude\skills\alpha'))
    ) 'inventory resolved the wrong consumer target'

    $duplicateManifest = Get-Content -Raw -LiteralPath (Join-Path $dotfiles 'manifests\skills.json') | ConvertFrom-Json
    $duplicateManifest.localSkills[0].name = 'alpha'
    $duplicateManifest.localSkills[0].consumers = @('codex')
    $duplicateFailure = $null
    try {
        $null = Get-SkillInventory -Manifest $duplicateManifest -DotfilesRoot $dotfiles `
            -SkillsRepository $repository -UserHome $testHome
    }
    catch {
        $duplicateFailure = $_.Exception.Message
    }
    Assert-True ($duplicateFailure -match 'Duplicate desired skill: codex/alpha') 'inventory did not reject a duplicate desired skill'

    $null = Invoke-Core -Migrate -ExpectedExitCode 0
    Assert-LinkTarget (Join-Path $testHome '.claude\skills\alpha') (Join-Path $repository 'skills\engineering\alpha')
    Assert-LinkTarget (Join-Path $testHome '.agents\skills\alpha') (Join-Path $repository 'skills\engineering\alpha')
    Assert-LinkTarget (Join-Path $testHome '.claude\skills\local-one') (Join-Path $dotfiles 'skills\shared\local-one')
    Assert-LinkTarget (Join-Path $testHome '.agents\skills\local-one') (Join-Path $dotfiles 'skills\shared\local-one')
    Assert-True (@(Get-ChildItem -Directory -LiteralPath $backups).Count -eq 1) 'migration backup was not created'

    $null = Invoke-Core -Check -ExpectedExitCode 0

    New-Item -ItemType Directory -Force -Path (Join-Path $repository 'skills\engineering\beta') | Out-Null
    @'
---
name: beta
description: Test beta.
---

Beta.
'@ | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $repository 'skills\engineering\beta\SKILL.md')
    Invoke-TestGit @('-C', $repository, 'add', '.')
    Invoke-TestGit @('-C', $repository, 'commit', '-m', 'add beta')

    New-Item -ItemType Directory -Force -Path (Join-Path $testHome '.claude\skills\beta') | Out-Null
    'modified' | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $testHome '.claude\skills\beta\SKILL.md')
    $failure = $null
    try {
        $null = Invoke-Core -Migrate -ExpectedExitCode 0
    }
    catch {
        $failure = $_.Exception.Message
    }
    Assert-True ($failure -match 'Refusing to migrate modified or unverified skill') 'modified collision was not rejected clearly'
    Assert-True (-not (Get-Item -Force -LiteralPath (Join-Path $testHome '.claude\skills\beta')).LinkType) 'modified collision was changed'

    $betaCollision = Join-Path $testHome '.claude\skills\beta'
    Assert-True ($betaCollision.StartsWith($testRoot, [StringComparison]::OrdinalIgnoreCase)) 'unsafe beta cleanup path'
    Remove-Item -Recurse -Force -LiteralPath $betaCollision
    $null = Invoke-Core -ExpectedExitCode 0

    $alphaSource = Join-Path $repository 'skills\engineering\alpha'
    Assert-True ($alphaSource.StartsWith($testRoot, [StringComparison]::OrdinalIgnoreCase)) 'unsafe alpha cleanup path'
    Remove-Item -Recurse -Force -LiteralPath $alphaSource
    Invoke-TestGit @('-C', $repository, 'add', '-A')
    Invoke-TestGit @('-C', $repository, 'commit', '-m', 'remove alpha')
    $null = Invoke-Core -ExpectedExitCode 0
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $testHome '.claude\skills\alpha'))) 'stale Claude link was not removed'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $testHome '.agents\skills\alpha'))) 'stale Codex link was not removed'

    # Keep one end-to-end subprocess path to cover CLI configuration, output,
    # and exit-code adaptation over the directly tested core.
    $null = Invoke-Updater -Arguments @('-NoPull', '-Check') -ExpectedExitCode 0

    Write-Host 'Skills synchronizer tests passed.'
}
finally {
    foreach ($name in 'DOTFILES_ROOT', 'SKILLS_REPO', 'SKILL_SYNC_HOME', 'SKILL_SYNC_STATE_ROOT', 'SKILL_SYNC_BACKUP_ROOT') {
        Remove-Item -LiteralPath "Env:$name" -ErrorAction SilentlyContinue
    }
    if (Test-Path -LiteralPath $testRoot) {
        $resolvedTestRoot = [IO.Path]::GetFullPath($testRoot)
        $resolvedTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
        if (-not $resolvedTestRoot.StartsWith($resolvedTemp, [StringComparison]::OrdinalIgnoreCase) -or $resolvedTestRoot -notmatch 'dotfiles-skill-test-') {
            throw "Refusing unsafe test cleanup: $resolvedTestRoot"
        }
        Remove-Item -Recurse -Force -LiteralPath $resolvedTestRoot
    }
}
