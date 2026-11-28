[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-True {
    param(
        [Parameter(Mandatory)] [bool] $Condition,
        [Parameter(Mandatory)] [string] $Message
    )

    if (-not $Condition) {
        throw "Assertion failed: $Message"
    }
}

$testRoot = Join-Path ([IO.Path]::GetTempPath()) ("dotfiles-profile-test-" + [Guid]::NewGuid().ToString('N'))
$profilePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'powershell\Microsoft.PowerShell_profile.ps1'
$originalEnvironment = @{}

try {
    foreach ($name in 'ANDROID_HOME', 'ANDROID_SDK_ROOT', 'JAVA_HOME', 'LG_CONFIG_FILE', 'LOCALAPPDATA', 'Path', 'PSModulePath', 'SCOOP') {
        $originalEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
    }

    $env:SCOOP = Join-Path $testRoot 'scoop'
    $env:LOCALAPPDATA = Join-Path $testRoot 'local-app-data'
    $env:Path = 'C:\keep'
    $psReadLine = Get-Module -ListAvailable -Name PSReadLine | Select-Object -First 1
    $env:PSModulePath = Split-Path (Split-Path $psReadLine.Path -Parent) -Parent
    foreach ($version in '17', '25') {
        New-Item -ItemType Directory -Force -Path (Join-Path $env:SCOOP "apps\temurin$version-jdk\current\bin") | Out-Null
    }
    $defaultJavaHome = Join-Path $env:SCOOP 'apps\temurin25-jdk\current'
    $env:JAVA_HOME = $defaultJavaHome
    $env:Path = "$(Join-Path $defaultJavaHome 'bin');C:\keep"

    # The profile follows this machine's saved theme, and finds the checkout
    # through its link, as when it is installed.
    New-Item -ItemType Directory -Force -Path (Join-Path $env:LOCALAPPDATA 'dotfiles') | Out-Null
    [IO.File]::WriteAllText((Join-Path $env:LOCALAPPDATA 'dotfiles\theme'), "dark-2026`n")
    $profileLink = Join-Path $testRoot 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $profileLink) | Out-Null
    New-Item -ItemType SymbolicLink -Path $profileLink -Target $profilePath | Out-Null
    New-Item -ItemType SymbolicLink -Path (Join-Path (Split-Path -Parent $profileLink) 'oh-my-posh') -Target (Join-Path (Split-Path -Parent $profilePath) 'oh-my-posh') | Out-Null
    $PROFILE = $profileLink

    . $profileLink

    Assert-True ($ompTheme -like '*\oh-my-posh\dark-2026.omp.json') "Oh My Posh does not use the saved theme: $ompTheme"
    Assert-True ($env:LG_CONFIG_FILE -like '*\shared\themes\lazygit\dark-2026.yml') "LazyGit does not use the saved theme: $env:LG_CONFIG_FILE"

    Assert-True ($null -ne (Get-Command jdk17 -ErrorAction SilentlyContinue)) 'jdk17 is not available'
    Assert-True ($null -ne (Get-Command jdk25 -ErrorAction SilentlyContinue)) 'jdk25 is not available'
    Assert-True ($env:JAVA_HOME -eq $defaultJavaHome) 'loading the profile changed the default Temurin 25 selection'

    jdk17
    $java17Home = Join-Path $env:SCOOP 'apps\temurin17-jdk\current'
    Assert-True ($env:JAVA_HOME -eq $java17Home) 'jdk17 did not select Temurin 17'
    Assert-True (($env:Path -split ';')[0] -eq (Join-Path $java17Home 'bin')) 'jdk17 did not prioritize Temurin 17 on PATH'

    jdk25
    $java25Home = Join-Path $env:SCOOP 'apps\temurin25-jdk\current'
    Assert-True ($env:JAVA_HOME -eq $java25Home) 'jdk25 did not select Temurin 25'
    Assert-True (($env:Path -split ';')[0] -eq (Join-Path $java25Home 'bin')) 'jdk25 did not prioritize Temurin 25 on PATH'
    Assert-True (-not ($env:Path -split ';' | Where-Object { $_ -ieq (Join-Path $java17Home 'bin') })) 'jdk25 left Temurin 17 on PATH'
    Assert-True ($env:Path -match [regex]::Escape('C:\keep')) 'switching JDKs removed an unmanaged PATH entry'

    Write-Host 'PowerShell profile tests passed.'
}
finally {
    foreach ($name in $originalEnvironment.Keys) {
        [Environment]::SetEnvironmentVariable($name, $originalEnvironment[$name], 'Process')
    }
    if (Test-Path -LiteralPath $testRoot) {
        $resolvedTestRoot = [IO.Path]::GetFullPath($testRoot)
        $resolvedTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
        if (-not $resolvedTestRoot.StartsWith($resolvedTemp, [StringComparison]::OrdinalIgnoreCase) -or $resolvedTestRoot -notmatch 'dotfiles-profile-test-') {
            throw "Refusing unsafe test cleanup: $resolvedTestRoot"
        }
        Remove-Item -Recurse -Force -LiteralPath $resolvedTestRoot
    }
}
