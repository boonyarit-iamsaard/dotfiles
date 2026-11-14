# 09: Extract theme files into `shared/`

**What to build:** Each theme file needed by more than one platform lives once
under `shared/`, following ticket 08's decisions, and every platform's links
point at it. Changing a theme means editing one place, and the theme-extras
drift test still guards vendored extras against their pin.

**Blocked by:** 08

**Where:** `shared/` and root from any machine; each platform's relink on its own machine.

**Status:** ready-for-agent

- [ ] No theme file is duplicated across platform folders
- [ ] The theme-extras drift test passes
- [ ] Mac: links updated, link check passes, themes render
- [ ] WSL: restow succeeds, tests pass, themes render
- [ ] Windows: links updated, `verify-system.ps1` passes, themes render
