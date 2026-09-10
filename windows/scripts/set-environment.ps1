[CmdletBinding()]
param([switch] $Check)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$dotfilesRoot = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $dotfilesRoot 'manifests\environment.json'
Import-Module (Join-Path $PSScriptRoot 'modules\ManagedEnvironment.psm1') -Force

if ($Check) {
    $failures = @(Test-ManagedEnvironment -ManifestPath $manifestPath -Target User)
    if ($failures.Count -gt 0) {
        $failures | ForEach-Object { Write-Error $_ }
        exit 1
    }

    Write-Host 'Managed user environment verification passed.'
    exit 0
}

$null = Set-ManagedEnvironment -ManifestPath $manifestPath -Target User
$null = Set-ManagedEnvironment -ManifestPath $manifestPath -Target Process

if (-not ('EnvironmentChangeNotifier' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class EnvironmentChangeNotifier
{
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern IntPtr SendMessageTimeout(
        IntPtr window,
        uint message,
        UIntPtr wParam,
        string lParam,
        uint flags,
        uint timeout,
        out UIntPtr result);
}
'@
}

$result = [UIntPtr]::Zero
$null = [EnvironmentChangeNotifier]::SendMessageTimeout(
    [IntPtr] 0xffff,
    0x001a,
    [UIntPtr]::Zero,
    'Environment',
    0x0002,
    5000,
    [ref] $result
)

Write-Host 'Managed user environment applied. New processes will inherit the changes.'
