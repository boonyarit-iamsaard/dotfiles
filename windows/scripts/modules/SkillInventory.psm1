Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-SkillManifestPath {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $UserHome
    )

    $expanded = $Path.Replace('{home}', $UserHome)
    return [IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables($expanded), $UserHome)
}

function Get-SkillInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [object] $Manifest,
        [Parameter(Mandatory)] [string] $PlatformRoot,
        [Parameter(Mandatory)] [string] $SkillsRepository,
        [Parameter(Mandatory)] [string] $UserHome
    )

    if ($Manifest.version -ne 2) {
        throw "Unsupported skills manifest version: $($Manifest.version)"
    }

    $consumerRoots = @{}
    foreach ($consumer in $Manifest.consumers.PSObject.Properties) {
        $consumerRoots[$consumer.Name] = Resolve-SkillManifestPath -Path ([string] $consumer.Value.target) -UserHome $UserHome
    }

    $desired = @{}
    $upstreamNames = @{}
    $skillsRoot = Join-Path $SkillsRepository 'skills'
    foreach ($category in @($Manifest.repository.categories)) {
        $categoryRoot = Join-Path $skillsRoot ([string] $category)
        if (-not (Test-Path -LiteralPath (Join-Path $categoryRoot 'README.md') -PathType Leaf)) {
            throw "Missing skill category catalog: $categoryRoot\README.md"
        }

        foreach ($skillDirectory in Get-ChildItem -Directory -LiteralPath $categoryRoot) {
            if (-not (Test-Path -LiteralPath (Join-Path $skillDirectory.FullName 'SKILL.md') -PathType Leaf)) {
                continue
            }
            if ($upstreamNames.ContainsKey($skillDirectory.Name)) {
                throw "Duplicate upstream skill name '$($skillDirectory.Name)'."
            }
            $upstreamNames[$skillDirectory.Name] = $true

            foreach ($consumerName in $consumerRoots.Keys) {
                $key = "$consumerName/$($skillDirectory.Name)"
                $desired[$key] = [pscustomobject]@{
                    Consumer = $consumerName
                    Name = $skillDirectory.Name
                    Source = $skillDirectory.FullName
                    Target = Join-Path $consumerRoots[$consumerName] $skillDirectory.Name
                    Provenance = 'upstream'
                }
            }
        }
    }

    $sharedRoot = Join-Path (Split-Path -Parent $PlatformRoot) 'shared\skills'
    foreach ($localSkill in @($Manifest.skills)) {
        $sources = @{}
        if ($localSkill.source -is [string]) {
            foreach ($consumerName in $consumerRoots.Keys) {
                $sources[$consumerName] = $localSkill.source
            }
        }
        else {
            foreach ($entry in $localSkill.source.PSObject.Properties) {
                if (-not $consumerRoots.ContainsKey($entry.Name)) {
                    throw "Unknown skills consumer: $($entry.Name)"
                }
                $sources[$entry.Name] = [string] $entry.Value
            }
            if ($sources.Count -ne $consumerRoots.Count -and
                (-not $localSkill.PSObject.Properties['reason'] -or -not $localSkill.reason)) {
                throw "Skill '$($localSkill.name)' skips a consumer without a reason."
            }
        }
        foreach ($consumerName in $sources.Keys) {
            $source = [IO.Path]::GetFullPath((Join-Path $sharedRoot $sources[$consumerName]))
            if (-not (Test-Path -LiteralPath (Join-Path $source 'SKILL.md') -PathType Leaf)) {
                throw "Personal or vendored skill is missing SKILL.md: $source"
            }
            $key = "$consumerName/$($localSkill.name)"
            if ($desired.ContainsKey($key)) {
                throw "Duplicate desired skill: $key"
            }
            $desired[$key] = [pscustomobject]@{
                Consumer = $consumerName
                Name = [string] $localSkill.name
                Source = $source
                Target = Join-Path $consumerRoots[$consumerName] ([string] $localSkill.name)
                Provenance = 'local'
            }
        }
    }

    return [pscustomobject]@{
        Skills = $desired
        ConsumerRoots = $consumerRoots
    }
}

Export-ModuleMember -Function 'Get-SkillInventory'
