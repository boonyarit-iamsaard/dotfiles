[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string[]] $Package,

    [switch] $Delete
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSEdition -ne 'Core' -or $PSVersionTable.PSVersion -lt [Version]'7.0') {
    throw 'PowerShell 7.0 or newer is required. Run this script with pwsh.exe.'
}

Import-Module (Join-Path $PSScriptRoot 'modules\ManagedWindowsLinks.psm1') -Force

$dotfilesRoot = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $dotfilesRoot 'manifests\links.json'
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
$availablePackages = @($manifest.PSObject.Properties.Name)

if (-not $Package) {
    $Package = $availablePackages
}

foreach ($packageName in $Package) {
    if ($packageName -notin $availablePackages) {
        throw "Unknown package '$packageName'. Available packages: $($availablePackages -join ', ')"
    }

    foreach ($mapping in $manifest.$packageName) {
        $source = [IO.Path]::GetFullPath((Join-Path $dotfilesRoot $mapping.source))
        $target = [Environment]::ExpandEnvironmentVariables($mapping.target)

        if ($Delete) {
            if (Test-ManagedLink -Path $target -Source $source) {
                Remove-ManagedLink -Path $target
                Write-Host "Unlinked $packageName`: $target"
            }
            elseif (Get-Item -Force -LiteralPath $target -ErrorAction SilentlyContinue) {
                throw "Refusing to remove non-managed path: $target"
            }
            else {
                Write-Host "Already unlinked $packageName`: $target"
            }
            continue
        }

        if (-not (Test-Path -LiteralPath $source)) {
            throw "Source path does not exist: $source"
        }

        if (Test-ManagedLink -Path $target -Source $source) {
            Write-Host "Already linked $packageName`: $target"
            continue
        }

        if (Get-Item -Force -LiteralPath $target -ErrorAction SilentlyContinue) {
            throw "Refusing to overwrite existing path: $target"
        }

        $isDirectory = Test-Path -LiteralPath $source -PathType Container
        New-ManagedLink -Path $target -Source $source -Directory $isDirectory
        Write-Host "Linked $packageName`: $target -> $source"
    }
}
