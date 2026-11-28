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

function Assert-Throws {
    param(
        [Parameter(Mandatory)] [scriptblock] $Action,
        [Parameter(Mandatory)] [string] $Pattern,
        [Parameter(Mandatory)] [string] $Message
    )

    try {
        & $Action
    }
    catch {
        Assert-True ($_.Exception.Message -match $Pattern) "$Message; got: $($_.Exception.Message)"
        return
    }
    throw "Assertion failed: $Message; nothing was thrown."
}

$setTheme = Join-Path $PSScriptRoot 'set-theme.ps1'
$trackedLazyDocker = Join-Path (Split-Path -Parent $PSScriptRoot) 'config\lazydocker\config.yml'
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ("dotfiles-set-theme-test-" + [Guid]::NewGuid().ToString('N'))
$originalEnvironment = @{}

try {
    foreach ($name in 'APPDATA', 'LOCALAPPDATA', 'USERPROFILE') {
        $originalEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
        [Environment]::SetEnvironmentVariable($name, (Join-Path $testRoot $name), 'Process')
    }

    $statePath = Join-Path $env:LOCALAPPDATA 'dotfiles\theme'
    $btopConfig = Join-Path $env:USERPROFILE 'scoop\apps\btop\current\btop.conf'
    $terminalSettings = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
    $lazyDockerConfig = Join-Path $env:APPDATA 'lazydocker\config.yml'
    foreach ($path in $btopConfig, $terminalSettings, $lazyDockerConfig) {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $path) | Out-Null
    }

    [IO.File]::WriteAllText($btopConfig, "color_theme = `"catppuccin-mocha`"`ntheme_background = False`n")
    [IO.File]::WriteAllText($terminalSettings, @'
{
    // keep this comment
    "profiles":
    {
        "defaults":
        {
            "colorScheme": "Dark Modern (VS Code)",
            "font": { "size": 10 }
        }
    }
}
'@)
    # The old setup linked lazydocker's config straight to the tracked file.
    New-Item -ItemType SymbolicLink -Path $lazyDockerConfig -Target $trackedLazyDocker | Out-Null
    $trackedBefore = [IO.File]::ReadAllText($trackedLazyDocker)

    # Saving a theme applies it to every tool.
    & $setTheme dark-2026

    Assert-True ([IO.File]::ReadAllText($statePath).Trim() -eq 'dark-2026') 'the choice was not saved'
    $btop = [IO.File]::ReadAllText($btopConfig)
    Assert-True ($btop -match '(?m)^color_theme = "dark-2026"$') 'btop color_theme was not set'
    Assert-True ($btop -match '(?m)^theme_background = False$') 'btop lost its other settings'
    $terminal = [IO.File]::ReadAllText($terminalSettings)
    Assert-True ($terminal -match '"colorScheme": "Dark 2026"') 'Windows Terminal colorScheme was not set'
    Assert-True ($terminal -match '// keep this comment') 'Windows Terminal settings lost a comment'
    Assert-True ($null -eq (Get-Item -LiteralPath $lazyDockerConfig).LinkType) 'the old lazydocker link was not replaced by a file'
    Assert-True ([IO.File]::ReadAllText($trackedLazyDocker) -ceq $trackedBefore) 'set-theme wrote through the link into the tracked lazydocker config'
    $lazyDocker = [IO.File]::ReadAllText($lazyDockerConfig)
    Assert-True ($lazyDocker -match '(?m)^# >>> theme: dark-2026$') 'lazydocker config does not name the theme'
    Assert-True ($lazyDocker -match '"#3994bc" # tab.activeBorderTop') 'lazydocker config lacks the dark-2026 variant colours'

    # The verify-system check agrees once a theme is applied, and notices drift.
    Import-Module (Join-Path $PSScriptRoot 'modules\ActiveTheme.psm1') -Force
    $checkoutRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    Assert-True (@(Test-ActiveTheme -CheckoutRoot $checkoutRoot).Count -eq 0) 'Test-ActiveTheme reported failures right after set-theme'
    [IO.File]::WriteAllText($btopConfig, ($btop -replace 'dark-2026', 'catppuccin-mocha'))
    Assert-True ((@(Test-ActiveTheme -CheckoutRoot $checkoutRoot) -join "`n") -match 'btop') 'Test-ActiveTheme missed a btop mismatch'

    # Without a name, set-theme re-applies the default and saves nothing.
    Remove-Item -LiteralPath $statePath
    & $setTheme
    Assert-True (-not (Test-Path -LiteralPath $statePath)) 're-applying saved a choice'
    Assert-True ([IO.File]::ReadAllText($btopConfig) -match '(?m)^color_theme = "catppuccin-macchiato"$') 're-applying did not use the default theme'
    Assert-True ([IO.File]::ReadAllText($terminalSettings) -match '"colorScheme": "Catppuccin Macchiato"') 're-applying did not set the default Terminal scheme'

    # An incomplete theme is refused and nothing changes. Oh My Posh's
    # nerd-font-symbols prompt has no file for any other tool.
    $before = @($btopConfig, $terminalSettings, $lazyDockerConfig | ForEach-Object { [IO.File]::ReadAllText($_) })
    Assert-Throws { & $setTheme nerd-font-symbols } 'LazyGit, LazyDocker, btop, Windows Terminal' 'an incomplete theme was not refused with its missing tools'
    Assert-Throws { & $setTheme no-such-theme } 'Unknown theme' 'an unknown theme was not refused'
    Assert-Throws { & $setTheme '..\evil' } 'Not a theme name' 'a path was accepted as a theme name'
    $after = @($btopConfig, $terminalSettings, $lazyDockerConfig | ForEach-Object { [IO.File]::ReadAllText($_) })
    Assert-True (($before -join '|') -ceq ($after -join '|')) 'a refused theme changed a config'
    Assert-True (-not (Test-Path -LiteralPath $statePath)) 'a refused theme was saved'

    # A lazydocker config that set-theme did not write is never overwritten.
    [IO.File]::WriteAllText($lazyDockerConfig, "gui: {}`n")
    Assert-Throws { & $setTheme catppuccin-mocha } 'not generated by set-theme' 'an unmanaged lazydocker config was not refused'
    Assert-True ([IO.File]::ReadAllText($lazyDockerConfig) -ceq "gui: {}`n") 'an unmanaged lazydocker config was overwritten'
    Assert-True ([IO.File]::ReadAllText($btopConfig) -match '"catppuccin-macchiato"') 'a refusal still changed btop'
    Remove-Item -LiteralPath $lazyDockerConfig

    # A Terminal settings file with no colorScheme gets one in profiles.defaults.
    [IO.File]::WriteAllText($terminalSettings, '{ "profiles": { "defaults": {}, "list": [] } }')
    & $setTheme catppuccin-mocha
    $terminal = [IO.File]::ReadAllText($terminalSettings)
    Assert-True ($terminal -match '"defaults": \{ "colorScheme": "Catppuccin Mocha"\}') "colorScheme was not added to profiles.defaults: $terminal"
    $null = $terminal | ConvertFrom-Json

    # -List shows complete themes only and marks the active one.
    $listing = @(& $setTheme -List)
    Assert-True ($listing -contains '* catppuccin-mocha') "-List did not mark the active theme: $($listing -join ', ')"
    Assert-True ($listing -contains '  dark-2026') '-List left out a complete theme'
    Assert-True (-not ($listing -match 'nerd-font-symbols')) '-List showed an incomplete theme'

    Write-Host 'set-theme tests passed.'
}
finally {
    foreach ($name in $originalEnvironment.Keys) {
        [Environment]::SetEnvironmentVariable($name, $originalEnvironment[$name], 'Process')
    }
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}
