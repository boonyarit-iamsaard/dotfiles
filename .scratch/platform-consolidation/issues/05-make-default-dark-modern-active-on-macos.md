# 05: Make Default Dark Modern the active macOS theme

**What to build:** On the Mac, Default Dark Modern is the active theme in
Ghostty, tmux, LazyGit, LazyDocker, btop, superfile and Neovim, so every
terminal tool matches. The other themes stay available as alternates.

Starting point (from `main` before ticket 04):

- **Ghostty, tmux, LazyGit, LazyDocker:** a Default Dark Modern theme file
  already exists; only the active selection changes. LazyGit is selected
  through `LG_CONFIG_FILE` (base config plus Theme variant); LazyDocker keeps
  its Theme variant contract (the active block is an exact copy of its theme
  file, guarded by the existing test).
- **Neovim:** `vscode.nvim` is already configured with Dark Modern overrides;
  the active colorscheme and the matching theme import switch to it.
- **superfile:** no Default Dark Modern theme exists; one is written from the
  VS Code Dark Modern colours, the same source the Neovim overrides cite.
- **btop:** not managed by the dotfiles on the Mac today, and no Default Dark
  Modern theme exists on any platform. btop's config comes under management
  (added to the macOS link list from ticket 03) with a new Dark Modern theme.

Colours not owned upstream by this repo follow the VS Code Dark Modern theme
definition. ADR-0001 governs only the Dark 2026 palette and is unaffected.

**Blocked by:** 04

**Where:** This Mac, in the live checkout on `main`. It is the last commit on
`main` before ticket 06 rebuilds the integration branch; after it, nothing
lands on `main` until ticket 12.

**Status:** done

- [x] Ghostty, tmux, LazyGit, LazyDocker, btop, superfile and Neovim all start in Default Dark Modern
- [x] Switching back to another theme is still a one-line change per tool
- [x] The LazyDocker Theme variant test and the theme-extras drift test pass
- [x] btop is in the macOS link list and the link check passes
- [x] New superfile and btop theme files cite the VS Code Dark Modern source
- [x] Pushed

## Outcome

- The switch is `c341baa` on `main`. Ghostty, Neovim and LazyDocker keep
  their existing switch shapes (commented alternates, a theme import, the
  marker block), and the README now has a switch row for every tool.
- The drift test failed because the Dark 2026 LazyGit extra put
  `authorColors` under `gui`; LazyGit 0.66 reads it under `gui.theme`. Fixed
  upstream in dark-2026.nvim `c1f8af7`; `2e8da3d` bumps the pin and
  re-vendors. The Default Dark Modern LazyGit variant got the same move.
- btop's `btop.conf`, the new Dark Modern theme and the Catppuccin Mocha
  theme are linked per file; `btop.log` and other themes stay local. btop
  saves its config on exit, so in-app changes edit the tracked file.
- superfile has no Chroma style for Dark Modern; code highlighting uses
  `github-dark`. Its config also had a `catppuccion` typo, now replaced.
- 48 tests pass; `check-links` reports 67 ok.
