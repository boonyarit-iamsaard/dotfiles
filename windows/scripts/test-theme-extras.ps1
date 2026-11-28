[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$checkoutRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $PSScriptRoot 'modules\ActiveTheme.psm1') -Force

# Every theme set-theme can apply has a file for each themed tool. Oh My Posh's
# nerd-font-symbols prompt is a standalone prompt, not a theme.
foreach ($theme in Get-ThemeCatalog -CheckoutRoot $checkoutRoot | Where-Object Name -NE 'nerd-font-symbols') {
    if ($theme.Missing.Count -gt 0) {
        throw "Theme $($theme.Name) has no file for: $($theme.Missing -join ', ')."
    }
}

# Keep the Windows pin aligned with the shared extras when refreshing themes.
$pin = '4d19b8f1c1af75ae67d58506fb144e6b09d68e1f'
$extras = [ordered]@{
    'shared/themes/lazygit/dark-2026.yml' = 'extras/lazygit/dark-2026.yml'
    'shared/themes/lazydocker/dark-2026.yml' = 'extras/lazydocker/dark-2026.yml'
    'shared/themes/btop/dark-2026.theme' = 'extras/btop/dark-2026.theme'
    'windows/config/windows-terminal/dark-2026.json' = 'extras/windows-terminal/dark-2026.json'
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

Write-Host 'Every theme is complete, and theme extras and Catppuccin files match their upstream pins.'
