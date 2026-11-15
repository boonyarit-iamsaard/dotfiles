[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$checkoutRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
# Keep the Windows pin aligned with the shared extras when refreshing themes.
$pin = '4d19b8f1c1af75ae67d58506fb144e6b09d68e1f'
$extras = [ordered]@{
    'shared/themes/lazygit/dark-2026.yml' = 'extras/lazygit/dark-2026.yml'
    'shared/themes/lazydocker/dark-2026.yml' = 'extras/lazydocker/dark-2026.yml'
    'shared/themes/btop/dark-2026.theme' = 'extras/btop/dark-2026.theme'
    'windows/config/windows-terminal/dark-2026.json' = 'extras/windows-terminal/dark-2026.json'
    'windows/powershell/oh-my-posh/dark-2026.omp.json' = 'extras/oh-my-posh/dark-2026.omp.json'
}

foreach ($extra in $extras.GetEnumerator()) {
    $upstream = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/boonyarit-iamsaard/dark-2026.nvim/$pin/$($extra.Value)"
    $actual = [IO.File]::ReadAllBytes((Join-Path $checkoutRoot $extra.Key))
    if ([Convert]::ToBase64String($actual) -cne [Convert]::ToBase64String($upstream.RawContentStream.ToArray())) {
        throw "Theme extra drift: $($extra.Key); re-copy $($extra.Value) from upstream pin $pin."
    }
}

$catppuccin = Get-Content -Raw (Join-Path $checkoutRoot 'shared/themes/catppuccin.json') | ConvertFrom-Json
foreach ($port in $catppuccin.PSObject.Properties) {
    foreach ($file in $port.Value.files.PSObject.Properties) {
        $url = "https://raw.githubusercontent.com/catppuccin/$($port.Name)/$($port.Value.commit)/$($file.Value)"
        $upstream = Invoke-WebRequest -Uri $url
        $actual = [IO.File]::ReadAllBytes((Join-Path $checkoutRoot "shared/themes/$($file.Name)"))
        if ([Convert]::ToBase64String($actual) -cne [Convert]::ToBase64String($upstream.RawContentStream.ToArray())) {
            throw "Catppuccin drift: shared/themes/$($file.Name); re-download from $url."
        }
    }
}

$config = [IO.File]::ReadAllText((Join-Path $checkoutRoot 'windows/config/lazydocker/config.yml')) -replace '\r\n', "`n"
$activeBlocks = [regex]::Matches($config, '(?ms)^# >>> theme: ([a-z0-9-]+)\n(.*?)^# <<< theme$')
if ($activeBlocks.Count -ne 1) {
    throw 'LazyDocker must have exactly one active theme marker block.'
}
$activeBlock = $activeBlocks[0]
$themeName = $activeBlock.Groups[1].Value
$variant = [IO.File]::ReadAllText((Join-Path $checkoutRoot "shared/themes/lazydocker/$themeName.yml")) -replace '\r\n', "`n"
$expectedBlock = ($variant -replace '\A(?:#[^\n]*\n|\n)*', '').TrimEnd("`n")
if ($activeBlock.Groups[2].Value.TrimEnd("`n") -cne $expectedBlock) {
    throw "LazyDocker active block differs from the shared $themeName variant."
}

Write-Host 'Theme extras, Catppuccin files and LazyDocker active block match their upstream pins.'
