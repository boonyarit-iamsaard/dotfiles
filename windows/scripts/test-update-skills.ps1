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
$platformRoot = Join-Path $testRoot 'windows'
$sharedRoot = Join-Path $testRoot 'shared\skills'
$manifestPath = Join-Path $sharedRoot 'skills.json'
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

    $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    $configuration = [pscustomobject]@{
        PlatformRoot = $platformRoot
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
    New-Item -ItemType Directory -Force -Path $platformRoot | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $sharedRoot 'local-one') | Out-Null
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
'@ | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $sharedRoot 'local-one\SKILL.md')

    Invoke-TestGit @('-C', $repository, 'init')
    Invoke-TestGit @('-C', $repository, 'config', 'user.name', 'Skill Test')
    Invoke-TestGit @('-C', $repository, 'config', 'user.email', 'skill-test@example.invalid')
    Invoke-TestGit @('-C', $repository, 'add', '.')
    Invoke-TestGit @('-C', $repository, 'commit', '-m', 'initial skills')

    @'
{
  "version": 2,
  "repository": {
    "url": "https://example.invalid/skills.git",
    "categories": ["engineering", "productivity"]
  },
  "consumers": {
    "agents": { "target": ".agents/skills" },
    "claude": { "target": ".claude/skills" }
  },
  "plugins": { "claude": [] },
  "skills": [
    {
      "name": "local-one",
      "source": "local-one"
    }
  ]
}
'@ | Set-Content -Encoding UTF8 -LiteralPath $manifestPath

    Copy-Item -Recurse -LiteralPath (Join-Path $repository 'skills\engineering\alpha') -Destination (Join-Path $testHome '.claude\skills\alpha')

    $env:DOTFILES_PLATFORM_ROOT = $platformRoot
    $env:SKILLS_REPO = $repository
    $env:SKILL_SYNC_HOME = $testHome
    $env:SKILL_SYNC_STATE_ROOT = $state
    $env:SKILL_SYNC_BACKUP_ROOT = $backups

    $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    $inventory = Get-SkillInventory -Manifest $manifest -PlatformRoot $platformRoot `
        -SkillsRepository $repository -UserHome $testHome
    Assert-True ($inventory.Skills.Count -eq 4) 'inventory did not produce every consumer/skill pair'
    Assert-True ($inventory.Skills['agents/local-one'].Provenance -eq 'local') 'inventory lost local skill provenance'
    Assert-True (
        (Test-PathEquivalent -Left $inventory.Skills['claude/alpha'].Target -Right (Join-Path $testHome '.claude\skills\alpha'))
    ) 'inventory resolved the wrong consumer target'

    $duplicateManifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    $duplicateManifest.skills[0].name = 'alpha'
    $duplicateFailure = $null
    try {
        $null = Get-SkillInventory -Manifest $duplicateManifest -PlatformRoot $platformRoot `
            -SkillsRepository $repository -UserHome $testHome
    }
    catch {
        $duplicateFailure = $_.Exception.Message
    }
    Assert-True ($duplicateFailure -match 'Duplicate desired skill: (agents|claude)/alpha') 'inventory did not reject a duplicate desired skill'

    $null = Invoke-Core -Migrate -ExpectedExitCode 0
    Assert-LinkTarget (Join-Path $testHome '.claude\skills\alpha') (Join-Path $repository 'skills\engineering\alpha')
    Assert-LinkTarget (Join-Path $testHome '.agents\skills\alpha') (Join-Path $repository 'skills\engineering\alpha')
    Assert-LinkTarget (Join-Path $testHome '.claude\skills\local-one') (Join-Path $sharedRoot 'local-one')
    Assert-LinkTarget (Join-Path $testHome '.agents\skills\local-one') (Join-Path $sharedRoot 'local-one')
    Assert-True (@(Get-ChildItem -Directory -LiteralPath $backups).Count -eq 1) 'migration backup was not created'

    $null = Invoke-Core -Check -ExpectedExitCode 0

    # Upgrade recorded ownership and moved sources without trusting other links.
    $legacySource = Join-Path $platformRoot 'skills\shared\local-one'
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $legacySource) | Out-Null
    Copy-Item -Recurse -LiteralPath (Join-Path $sharedRoot 'local-one') -Destination $legacySource
    $agentsLink = Join-Path $testHome '.agents\skills\local-one'
    Remove-ManagedLink -Path $agentsLink
    New-ManagedLink -Path $agentsLink -Source $legacySource -Directory $true
    $staleClaudeLink = Join-Path $testHome '.claude\skills\ponytail'
    New-ManagedLink -Path $staleClaudeLink -Source $legacySource -Directory $true
    $statePath = Join-Path $state 'managed-links.json'
    $legacyState = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
    foreach ($entry in $legacyState.links) {
        if ($entry.consumer -eq 'agents') { $entry.consumer = 'codex' }
        if ($entry.consumer -eq 'codex' -and $entry.name -eq 'local-one') { $entry.source = $legacySource }
    }
    $legacyState.links += [pscustomobject]@{ consumer = 'claude'; name = 'ponytail'; source = $legacySource }
    $legacyState | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $statePath
    $null = Invoke-Core -Check -ExpectedExitCode 1
    Assert-LinkTarget $agentsLink $legacySource
    $null = Invoke-Core -ExpectedExitCode 0
    Assert-LinkTarget $agentsLink (Join-Path $sharedRoot 'local-one')
    Assert-True (-not (Get-Item -Force -LiteralPath $staleClaudeLink -ErrorAction SilentlyContinue)) 'old Claude Ponytail link was not retired'
    $null = Invoke-Core -Check -ExpectedExitCode 0

    # Per-consumer sources must resolve to their declared provider builds.
    foreach ($provider in 'agents', 'claude') {
        $providerRoot = Join-Path $sharedRoot $provider
        New-Item -ItemType Directory -Force -Path $providerRoot | Out-Null
        "---`nname: provider-one`ndescription: Provider fixture.`n---`n" |
            Set-Content -LiteralPath (Join-Path $providerRoot 'SKILL.md')
    }
    $providerManifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    $providerManifest.skills += [pscustomobject]@{ name = 'provider-one'; source = [pscustomobject]@{ agents = 'agents'; claude = 'claude' } }
    $providerManifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath
    $null = Invoke-Core -ExpectedExitCode 0
    Assert-LinkTarget (Join-Path $testHome '.agents\skills\provider-one') (Join-Path $sharedRoot 'agents')
    Assert-LinkTarget (Join-Path $testHome '.claude\skills\provider-one') (Join-Path $sharedRoot 'claude')

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

    # Fake only the external CLI; run the real sync and its on-disk pin checks.
    $previousClaude = Get-Item Function:claude -ErrorAction SilentlyContinue
    $previousClaudeConfig = $env:CLAUDE_CONFIG_DIR
    $global:DotfilesPluginFixture = [pscustomobject]@{
        Market = $null
        Installed = $false
        Enabled = $false
        Pin = ([string] (& git -C $repository rev-parse HEAD)).Trim()
        Repository = $repository
        PluginPath = Join-Path $testRoot 'plugin-cache'
        RecordPath = Join-Path $testHome '.claude\plugins\installed_plugins.json'
    }
    try {
        $env:CLAUDE_CONFIG_DIR = Join-Path $testHome '.claude'
        function global:claude {
            param([Parameter(ValueFromRemainingArguments)] [string[]] $Arguments)
            $global:LASTEXITCODE = 0
            $fixture = $global:DotfilesPluginFixture
            $request = @($Arguments | Select-Object -Skip 3)
            switch ($request[0]) {
                'marketplace' {
                    switch ($request[1]) {
                        'list' { ConvertTo-Json -InputObject @($fixture.Market | Where-Object { $_ }) -Depth 5 }
                        'add' {
                            $source = $request[2].Split('#')
                            $fixture.Market = [pscustomobject]@{
                                name = 'ponytail'; source = 'github'; repo = $source[0]; ref = $source[1]; installLocation = $fixture.Repository
                            }
                        }
                        'remove' { $fixture.Market = $null }
                    }
                }
                'list' {
                    $plugins = if ($fixture.Installed) {
                        [pscustomobject]@{ id = 'ponytail@ponytail'; scope = 'user'; enabled = $fixture.Enabled }
                    }
                    ConvertTo-Json -InputObject @($plugins | Where-Object { $_ })
                }
                'install' {
                    $fixture.Installed = $true
                    $fixture.Enabled = $true
                    New-Item -ItemType Directory -Force -Path $fixture.PluginPath, (Split-Path -Parent $fixture.RecordPath) | Out-Null
                    @{ version = 2; plugins = @{ 'ponytail@ponytail' = @(@{
                                scope = 'user'; gitCommitSha = $fixture.Pin; installPath = $fixture.PluginPath
                            }) } } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $fixture.RecordPath
                }
                'update' { }
                'enable' {
                    if ($fixture.Enabled) {
                        $global:LASTEXITCODE = 1
                        'Plugin is already enabled at user scope.'
                    }
                    else { $fixture.Enabled = $true }
                }
                default { throw "Unexpected fake Claude request: $($Arguments -join ' ')" }
            }
        }
        $pluginManifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
        $pluginManifest.plugins.claude = @([pscustomobject]@{
                plugin = 'ponytail@ponytail'; marketplace = 'example/ponytail'; ref = $global:DotfilesPluginFixture.Pin
            })
        $pluginManifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath
        $null = Invoke-Core -Check -ExpectedExitCode 1
        Assert-True (-not $global:DotfilesPluginFixture.Installed) 'plugin check changed external state'
        $null = Invoke-Core -ExpectedExitCode 0
        $null = Invoke-Core -Check -ExpectedExitCode 0
        $repeat = Invoke-Core -ExpectedExitCode 0
        Assert-True ($repeat.Actions.Count -eq 0 -and $repeat.Messages.Count -eq 0) 'repeated plugin sync was not idempotent'
        $global:DotfilesPluginFixture.Enabled = $false
        $null = Invoke-Core -Check -ExpectedExitCode 1
        $null = Invoke-Core -ExpectedExitCode 0
        $null = Invoke-Core -Check -ExpectedExitCode 0
    }
    finally {
        $env:CLAUDE_CONFIG_DIR = $previousClaudeConfig
        if ($previousClaude) { Set-Item Function:global:claude $previousClaude.ScriptBlock }
        else { Remove-Item Function:global:claude }
        Remove-Variable -Name DotfilesPluginFixture -Scope Global
    }

    Write-Host 'Skills synchronizer tests passed.'
}
finally {
    foreach ($name in 'DOTFILES_PLATFORM_ROOT', 'SKILLS_REPO', 'SKILL_SYNC_HOME', 'SKILL_SYNC_STATE_ROOT', 'SKILL_SYNC_BACKUP_ROOT') {
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
