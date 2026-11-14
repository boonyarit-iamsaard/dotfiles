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

**Status:** ready-for-agent

- [ ] Ghostty, tmux, LazyGit, LazyDocker, btop, superfile and Neovim all start in Default Dark Modern
- [ ] Switching back to another theme is still a one-line change per tool
- [ ] The LazyDocker Theme variant test and the theme-extras drift test pass
- [ ] btop is in the macOS link list and the link check passes
- [ ] New superfile and btop theme files cite the VS Code Dark Modern source
- [ ] Pushed
