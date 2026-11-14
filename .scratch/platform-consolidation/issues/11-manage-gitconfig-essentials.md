# 11: Manage `~/.gitconfig` essentials per platform

**What to build:** The Git settings this repo relies on (at least
`core.symlinks`, so symlinked `CLAUDE.md` files check out as links) come from
each platform's managed config, so a fresh machine gets them without manual
steps. Personal identity and machine-only settings (such as Windows'
`http.sslBackend`) stay out of the shared part.

**Blocked by:** 07

**Where:** Each platform's machine.

**Status:** ready-for-agent

- [ ] The essentials are declared once and included by each platform
- [ ] Mac: managed, link check passes, `git config core.symlinks` is true
- [ ] WSL: managed, restow succeeds
- [ ] Windows: managed, `verify-system.ps1` passes
