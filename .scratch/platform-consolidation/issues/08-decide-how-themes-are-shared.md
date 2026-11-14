# 08: Decide how themes are shared

**What to build:** A grilling session settles how themes are shared across the
three platforms, recorded as decisions. ADR-0001 stands unless a new ADR
supersedes it: the Dark 2026 palette is owned by the upstream `dark-2026.nvim`
repo and theme extras are vendored at the lazy-lock pin. Questions to settle:
how Windows' hand-ported theme files (Windows Terminal, Oh My Posh, LazyGit,
LazyDocker) fit the vendored-extras model; how Default Dark Modern, Catppuccin
Mocha and One Dark are sourced; whether LazyGit moves to a shared base plus a
Theme variant via `LG_CONFIG_FILE`; how LazyDocker, which cannot include files,
is handled; where shared theme files live under `shared/`.

**Blocked by:** 07

**Where:** Any machine (decision only, no config changes).

**Status:** ready-for-agent

- [ ] Each question above has a recorded answer
- [ ] Any reversal of ADR-0001 is a new ADR that supersedes it
- [ ] New or sharpened terms are in the glossary
- [ ] Ticket 09's scope is updated to match the decisions
