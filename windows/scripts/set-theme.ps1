[CmdletBinding(DefaultParameterSetName = 'Apply')]
param(
    # The theme to save and apply; omit it to re-apply the saved or default theme.
    [Parameter(Position = 0, ParameterSetName = 'Apply')]
    [string] $Name,

    [Parameter(Mandatory, ParameterSetName = 'List')]
    [switch] $List
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'modules\ActiveTheme.psm1') -Force
$checkoutRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$active = Get-ActiveTheme

if ($List) {
    foreach ($theme in Get-ThemeCatalog -CheckoutRoot $checkoutRoot | Where-Object { $_.Missing.Count -eq 0 }) {
        $marker = if ($theme.Name -eq $active) { '* ' } else { '  ' }
        Write-Output "$marker$($theme.Name)"
    }
    return
}

if ($Name) {
    Invoke-ActiveTheme -CheckoutRoot $checkoutRoot -Name $Name -Save
}
else {
    Invoke-ActiveTheme -CheckoutRoot $checkoutRoot -Name $active
    $Name = $active
}
Write-Host "Applied theme $Name. Open a new shell, and restart running tools, to see it."
