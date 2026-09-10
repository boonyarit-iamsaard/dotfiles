Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ManagedEnvironmentConfiguration {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string] $ManifestPath)

    $manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
    $directoryVariables = [ordered]@{}
    foreach ($property in $manifest.directoryVariables.PSObject.Properties) {
        $value = [Environment]::ExpandEnvironmentVariables([string] $property.Value)
        $directoryVariables[$property.Name] = [IO.Path]::GetFullPath($value).TrimEnd('\')
    }

    $pathEntries = @($manifest.pathEntries | ForEach-Object {
            $value = [Environment]::ExpandEnvironmentVariables([string] $_)
            [IO.Path]::GetFullPath($value).TrimEnd('\')
        })

    [pscustomobject]@{
        DirectoryVariables = $directoryVariables
        PathEntries = $pathEntries
    }
}

function Set-ManagedEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $ManifestPath,
        [ValidateSet('Process', 'User')] [string] $Target = 'User'
    )

    $configuration = Get-ManagedEnvironmentConfiguration -ManifestPath $ManifestPath
    foreach ($entry in $configuration.DirectoryVariables.GetEnumerator()) {
        [Environment]::SetEnvironmentVariable($entry.Key, $entry.Value, $Target)
    }

    $preferred = @($configuration.PathEntries)
    $currentPath = [Environment]::GetEnvironmentVariable('Path', $Target)
    $preserved = @($currentPath -split ';' | Where-Object {
            $candidate = $_
            $candidate -and -not ($preferred | Where-Object {
                    $_.TrimEnd('\') -ieq $candidate.TrimEnd('\')
                })
        })
    $updatedPath = (@($preferred) + $preserved) -join ';'
    [Environment]::SetEnvironmentVariable('Path', $updatedPath, $Target)
    return $updatedPath
}

function Test-ManagedEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $ManifestPath,
        [ValidateSet('Process', 'User')] [string] $Target = 'User'
    )

    $configuration = Get-ManagedEnvironmentConfiguration -ManifestPath $ManifestPath
    $failures = [Collections.Generic.List[string]]::new()

    foreach ($entry in $configuration.DirectoryVariables.GetEnumerator()) {
        $actual = [Environment]::GetEnvironmentVariable($entry.Key, $Target)
        if (-not $actual -or $actual.TrimEnd('\') -ine $entry.Value) {
            $failures.Add("Environment variable $($entry.Key) is not set to $($entry.Value).")
        }
    }

    $actualEntries = @([Environment]::GetEnvironmentVariable('Path', $Target) -split ';' | Where-Object { $_ })
    for ($index = 0; $index -lt $configuration.PathEntries.Count; $index++) {
        $expected = $configuration.PathEntries[$index]
        $matches = @($actualEntries | Where-Object { $_.TrimEnd('\') -ieq $expected }).Count
        if ($matches -ne 1) {
            $failures.Add("User Path must contain exactly one managed entry: $expected")
        }
        elseif ($index -ge $actualEntries.Count -or $actualEntries[$index].TrimEnd('\') -ine $expected) {
            $failures.Add("User Path does not prioritize the managed entry: $expected")
        }
    }

    return $failures
}

Export-ModuleMember -Function Set-ManagedEnvironment, Test-ManagedEnvironment
