Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-SkillManifestPath {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $UserHome
    )

    $expanded = $Path.Replace('{home}', $UserHome)
    return [IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables($expanded))
}

function Get-SkillInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [object] $Manifest,
        [Parameter(Mandatory)] [string] $DotfilesRoot,
        [Parameter(Mandatory)] [string] $SkillsRepository,
        [Parameter(Mandatory)] [string] $UserHome
    )

    if ($Manifest.version -ne 1) {
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

    foreach ($localSkill in @($Manifest.localSkills)) {
        $source = [IO.Path]::GetFullPath((Join-Path $DotfilesRoot ([string] $localSkill.source)))
        if (-not (Test-Path -LiteralPath (Join-Path $source 'SKILL.md') -PathType Leaf)) {
            throw "Local skill is missing SKILL.md: $source"
        }
        foreach ($consumer in @($localSkill.consumers)) {
            $consumerName = [string] $consumer
            if (-not $consumerRoots.ContainsKey($consumerName)) {
                throw "Unknown skills consumer: $consumerName"
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
