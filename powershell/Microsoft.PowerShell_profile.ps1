# PowerShell 7 profile.
#
# Managed by the dotfiles repository. The real file lives in
# dotfiles\powershell and is symlinked to $PROFILE by
# scripts\link-dotfiles.ps1, so $PSScriptRoot below resolves to
# Documents\PowerShell either way.

# ---------------------------------------------------------------------------
# Prompt
# ---------------------------------------------------------------------------
# Oh My Posh renders the prompt. The theme is the Catppuccin Mocha powerline
# bar that this configuration used under Starship on the other branches.
$ompTheme = Join-Path $PSScriptRoot 'oh-my-posh\catppuccin-mocha.omp.json'
$ompCommand = Get-Command oh-my-posh -ErrorAction SilentlyContinue

if ($ompCommand) {
    & $ompCommand.Source init pwsh --config $ompTheme | Invoke-Expression
}
else {
    Write-Warning 'Oh My Posh was not found on PATH. Reopen the terminal after installing it.'
}

# ---------------------------------------------------------------------------
# Modules
# ---------------------------------------------------------------------------
# Terminal-Icons comes from the PowerShell Gallery, not Scoop:
#   Install-Module Terminal-Icons -Scope CurrentUser
if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module -Name Terminal-Icons
}

Import-Module PSReadLine

# ---------------------------------------------------------------------------
# Line editing
# ---------------------------------------------------------------------------
# Vi editing with `jj` as the escape chord, matching `bindkey jj vi-cmd-mode`
# from the zsh configuration. Some embedded console hosts report interactivity
# without supporting PSReadLine rendering, hence the guard and the try block.
if ($Host.Name -eq 'ConsoleHost' -and -not [Console]::IsOutputRedirected) {
    try {
        Set-PSReadLineOption -EditMode Vi -ErrorAction Stop
        # Cursor shape marks the mode: a blinking bar while inserting and a
        # blinking block in command mode. PSReadLine's own `Cursor` indicator
        # only switches between an underline and a block.
        Set-PSReadLineOption -ViModeIndicator Script -ErrorAction Stop
        Set-PSReadLineOption -ViModeChangeHandler {
            if ($args[0] -eq 'Command') {
                Write-Host -NoNewline "`e[1 q"
            }
            else {
                Write-Host -NoNewline "`e[5 q"
            }
        } -ErrorAction Stop
        Set-PSReadLineOption -PredictionSource History -ErrorAction Stop
        Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction Stop

        Set-PSReadLineKeyHandler -Chord 'j,j' -ViMode Insert -BriefDescription 'ViCommandMode' `
            -LongDescription 'Leave insert mode, like jj in vi-mode zsh.' -ScriptBlock {
            [Microsoft.PowerShell.PSConsoleReadLine]::ViCommandMode()
        }
    }
    catch {
        # Leave PSReadLine at its defaults when the host cannot support these.
    }

    # The prompt starts in insert mode, so match the cursor to it.
    Write-Host -NoNewline "`e[5 q"
}

# ---------------------------------------------------------------------------
# Aliases
# ---------------------------------------------------------------------------
Set-Alias -Name lzg -Value lazygit
