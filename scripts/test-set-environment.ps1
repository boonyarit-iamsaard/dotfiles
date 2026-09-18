[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'modules\ManagedEnvironment.psm1') -Force

function Assert-True {
    param(
        [Parameter(Mandatory)] [bool] $Condition,
        [Parameter(Mandatory)] [string] $Message
    )

    if (-not $Condition) {
        throw "Assertion failed: $Message"
    }
}

$testRoot = Join-Path ([IO.Path]::GetTempPath()) ("dotfiles-environment-test-" + [Guid]::NewGuid().ToString('N'))
$localAppData = Join-Path $testRoot 'local-app-data'
$userProfile = Join-Path $testRoot 'home'
$androidHome = Join-Path $localAppData 'Android\Sdk'
$javaHome = Join-Path $userProfile 'scoop\apps\temurin25-jdk\current'
$manifestPath = Join-Path $testRoot 'environment.json'
$originalEnvironment = @{}

try {
    foreach ($name in 'ANDROID_HOME', 'JAVA_HOME', 'LOCALAPPDATA', 'USERPROFILE', 'Path') {
        $originalEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
    }

    foreach ($path in @(
            $androidHome
            (Join-Path $androidHome 'platform-tools')
            (Join-Path $androidHome 'emulator')
            $javaHome
            (Join-Path $javaHome 'bin')
        )) {
        New-Item -ItemType Directory -Force -Path $path | Out-Null
    }

    @'
{
  "directoryVariables": {
    "ANDROID_HOME": "%LOCALAPPDATA%\\Android\\Sdk",
    "JAVA_HOME": "%USERPROFILE%\\scoop\\apps\\temurin25-jdk\\current"
  },
  "pathEntries": [
    "%USERPROFILE%\\scoop\\apps\\temurin25-jdk\\current\\bin",
    "%LOCALAPPDATA%\\Android\\Sdk\\platform-tools",
    "%LOCALAPPDATA%\\Android\\Sdk\\emulator",
    "%LOCALAPPDATA%\\Android\\Sdk\\cmdline-tools\\latest\\bin"
  ]
}
'@ | Set-Content -Encoding UTF8 -LiteralPath $manifestPath

    $env:LOCALAPPDATA = $localAppData
    $env:USERPROFILE = $userProfile
    $env:ANDROID_HOME = 'C:\stale-android'
    $env:JAVA_HOME = 'C:\stale-java'
    $env:Path = "C:\keep;$($androidHome)\platform-tools\"

    $firstPath = Set-ManagedEnvironment -ManifestPath $manifestPath -Target Process
    Assert-True ($env:ANDROID_HOME -eq $androidHome) 'ANDROID_HOME was not resolved from the manifest'
    Assert-True ($env:JAVA_HOME -eq $javaHome) 'JAVA_HOME was not resolved from the manifest'
    Assert-True ($env:Path.StartsWith((Join-Path $javaHome 'bin'), [StringComparison]::OrdinalIgnoreCase)) 'the default JDK is not first on PATH'
    Assert-True ((@($env:Path -split ';' | Where-Object { $_.TrimEnd('\') -ieq (Join-Path $androidHome 'platform-tools') })).Count -eq 1) 'PATH contains duplicate platform-tools entries'
    Assert-True ($env:Path -match [regex]::Escape((Join-Path $androidHome 'cmdline-tools\latest\bin'))) 'a declared PATH entry was skipped because its directory does not exist yet'
    Assert-True ($env:Path -match [regex]::Escape('C:\keep')) 'an unmanaged PATH entry was removed'
    Assert-True (@(Test-ManagedEnvironment -ManifestPath $manifestPath -Target Process).Count -eq 0) 'a freshly applied environment reports drift'

    $failures = @(Test-ManagedEnvironment -ManifestPath $manifestPath -Target Process -RequireDirectories)
    Assert-True ($failures.Count -eq 1) 'a missing managed directory was not detected when directory verification was requested'
    Assert-True ($failures[0] -match [regex]::Escape((Join-Path $androidHome 'cmdline-tools\latest\bin'))) 'the missing managed directory failure did not name the directory'

    $secondPath = Set-ManagedEnvironment -ManifestPath $manifestPath -Target Process
    Assert-True ($secondPath -eq $firstPath) 'a second apply changed PATH'

    $env:ANDROID_HOME = 'C:\drifted'
    $failures = @(Test-ManagedEnvironment -ManifestPath $manifestPath -Target Process)
    Assert-True ($failures.Count -eq 1) 'environment drift was not detected'
    Assert-True ($failures[0] -match 'ANDROID_HOME') 'environment drift did not name ANDROID_HOME'

    Remove-Item Env:ANDROID_HOME
    $failures = @(Test-ManagedEnvironment -ManifestPath $manifestPath -Target Process)
    Assert-True ($failures.Count -eq 1) 'a missing environment variable was not detected'

    Write-Host 'Managed environment tests passed.'
}
finally {
    foreach ($name in $originalEnvironment.Keys) {
        [Environment]::SetEnvironmentVariable($name, $originalEnvironment[$name], 'Process')
    }
    if (Test-Path -LiteralPath $testRoot) {
        $resolvedTestRoot = [IO.Path]::GetFullPath($testRoot)
        $resolvedTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
        if (-not $resolvedTestRoot.StartsWith($resolvedTemp, [StringComparison]::OrdinalIgnoreCase) -or $resolvedTestRoot -notmatch 'dotfiles-environment-test-') {
            throw "Refusing unsafe test cleanup: $resolvedTestRoot"
        }
        Remove-Item -Recurse -Force -LiteralPath $resolvedTestRoot
    }
}
