Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not ('Dotfiles.ManagedSymbolicLink' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

namespace Dotfiles
{
    public static class ManagedSymbolicLink
    {
        private const int DirectoryFlag = 0x1;
        private const int AllowUnprivilegedFlag = 0x2;

        [DllImport("kernel32.dll", EntryPoint = "CreateSymbolicLinkW",
            CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool CreateSymbolicLink(
            string linkPath,
            string targetPath,
            int flags
        );

        public static void Create(string linkPath, string targetPath, bool isDirectory)
        {
            int flags = AllowUnprivilegedFlag;
            if (isDirectory)
            {
                flags |= DirectoryFlag;
            }

            if (!CreateSymbolicLink(linkPath, targetPath, flags))
            {
                throw new Win32Exception(Marshal.GetLastWin32Error());
            }
        }
    }
}
'@
}

function Get-ManagedLinkTarget {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string] $Path)

    $item = Get-Item -Force -LiteralPath $Path -ErrorAction SilentlyContinue
    if (-not $item -or $item.LinkType -ne 'SymbolicLink') {
        return $null
    }

    $target = [string] $item.Target
    if (-not [IO.Path]::IsPathRooted($target)) {
        $target = Join-Path (Split-Path -Parent $Path) $target
    }
    return [IO.Path]::GetFullPath($target)
}

function Test-PathEquivalent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Left,
        [Parameter(Mandatory)] [string] $Right
    )

    return [string]::Equals(
        [IO.Path]::GetFullPath($Left).TrimEnd('\'),
        [IO.Path]::GetFullPath($Right).TrimEnd('\'),
        [StringComparison]::OrdinalIgnoreCase
    )
}

function Test-ManagedLink {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $Source
    )

    $target = Get-ManagedLinkTarget -Path $Path
    return $null -ne $target -and (Test-PathEquivalent -Left $target -Right $Source)
}

function New-ManagedLink {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $Source,
        [Parameter(Mandatory)] [bool] $Directory
    )

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
    try {
        [Dotfiles.ManagedSymbolicLink]::Create($Path, $Source, $Directory)
    }
    catch [ComponentModel.Win32Exception] {
        if ($_.Exception.NativeErrorCode -eq 1314) {
            throw 'Creating symlinks requires Windows Developer Mode. Enable it in Settings > System > Advanced > For developers, then rerun this script.'
        }
        throw
    }
}

function Remove-ManagedLink {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string] $Path)

    $item = Get-Item -Force -LiteralPath $Path -ErrorAction SilentlyContinue
    if (-not $item -or $item.LinkType -ne 'SymbolicLink') {
        throw "Refusing to remove a non-symlink path: $Path"
    }

    # Delete the reparse point itself without traversing its target. This also
    # works when the target no longer exists.
    if (($item.Attributes -band [IO.FileAttributes]::Directory) -ne 0) {
        [IO.Directory]::Delete($Path)
    }
    else {
        [IO.File]::Delete($Path)
    }
}

Export-ModuleMember -Function @(
    'Get-ManagedLinkTarget',
    'Test-PathEquivalent',
    'Test-ManagedLink',
    'New-ManagedLink',
    'Remove-ManagedLink'
)
