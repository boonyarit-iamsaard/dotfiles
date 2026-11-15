Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-ClaudePluginCommand {
    param([Parameter(Mandatory)] [string[]] $Arguments)

    $output = @(& claude --setting-sources user plugin @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "claude plugin $($Arguments -join ' ') failed:`n$($output -join [Environment]::NewLine)"
    }
    return $output -join [Environment]::NewLine
}

function Invoke-ClaudeSkillPlugins {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [object] $Manifest,
        [Parameter(Mandatory)] [string] $UserHome,
        [switch] $ReadOnly
    )

    $entries = @($Manifest.plugins.claude)
    if ($entries.Count -eq 0) { return }
    if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
        throw 'Claude Code is required to install the plugins declared in shared/skills/skills.json.'
    }

    $marketplaces = @(Invoke-ClaudePluginCommand @('marketplace', 'list', '--json') | ConvertFrom-Json)
    $plugins = @(Invoke-ClaudePluginCommand @('list', '--json') | ConvertFrom-Json)
    $configRoot = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $UserHome '.claude' }
    $installedPath = Join-Path $configRoot 'plugins\installed_plugins.json'
    $installed = if (Test-Path -LiteralPath $installedPath) {
        Get-Content -Raw -LiteralPath $installedPath | ConvertFrom-Json
    }

    $changed = $false
    foreach ($entry in $entries) {
        $name = ([string] $entry.plugin).Split('@')[1]
        $market = @($marketplaces | Where-Object name -eq $name) | Select-Object -First 1
        if ($market -and ($market.source -ne 'github' -or $market.repo -ne $entry.marketplace)) {
            throw "Refusing to replace an unrelated Claude marketplace: $name"
        }
        $pinned = $market -and $market.PSObject.Properties['ref'] -and $market.ref -eq $entry.ref
        if ($pinned) {
            $head = & git -C $market.installLocation rev-parse HEAD 2>$null
            $pinned = $LASTEXITCODE -eq 0 -and $head -eq $entry.ref
        }
        $active = @($plugins | Where-Object { $_.id -eq $entry.plugin -and $_.scope -eq 'user' -and $_.enabled })
        $record = if ($installed -and $installed.plugins.PSObject.Properties[$entry.plugin]) {
            @($installed.plugins.($entry.plugin) | Where-Object scope -eq 'user') | Select-Object -First 1
        }
        $current = $record -and $record.PSObject.Properties['gitCommitSha'] -and
            $record.gitCommitSha -eq $entry.ref -and (Test-Path -LiteralPath $record.installPath)
        if ($pinned -and $current -and $active.Count -gt 0) { continue }

        if ($ReadOnly) {
            "Claude plugin needs synchronization: $($entry.plugin) at $($entry.ref)"
            continue
        }
        if (-not $pinned) {
            if ($market) { $null = Invoke-ClaudePluginCommand @('marketplace', 'remove', $name, '--scope', 'user') }
            $null = Invoke-ClaudePluginCommand @('marketplace', 'add', "$($entry.marketplace)#$($entry.ref)", '--scope', 'user')
        }
        $null = Invoke-ClaudePluginCommand @('install', [string] $entry.plugin, '--scope', 'user')
        $null = Invoke-ClaudePluginCommand @('update', [string] $entry.plugin, '--scope', 'user')
        $enabled = @(Invoke-ClaudePluginCommand @('list', '--json') | ConvertFrom-Json |
            Where-Object { $_.id -eq $entry.plugin -and $_.scope -eq 'user' -and $_.enabled })
        if ($enabled.Count -eq 0) {
            $null = Invoke-ClaudePluginCommand @('enable', [string] $entry.plugin, '--scope', 'user')
        }
        $changed = $true
        "Claude plugin synchronized: $($entry.plugin) at $($entry.ref)"
    }
    if ($changed) {
        $remaining = @(Invoke-ClaudeSkillPlugins -Manifest $Manifest -UserHome $UserHome -ReadOnly)
        if ($remaining.Count -gt 0) { throw ($remaining -join [Environment]::NewLine) }
    }
}

Export-ModuleMember -Function 'Invoke-ClaudeSkillPlugins'
