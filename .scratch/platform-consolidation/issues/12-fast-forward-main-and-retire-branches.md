# 12: Fast-forward `main` and retire the platform branches

**What to build:** `main` moves to the integration branch's tip as a true
fast-forward, and every machine tracks `main`, using only its own platform
folder. The `windows`, `wsl` and integration branches are retired; their
archive tags keep the old commits reachable.

**Blocked by:** 09, 10, 11

**Where:** Any machine for the branch move; each machine for its switch.

**Status:** ready-for-agent

- [ ] `main` fast-forwards to the integration tip with no new commit
- [ ] Mac: on `main`, no file changes on switch, link check passes
- [ ] WSL: on `main`, restow unchanged, tests pass
- [ ] Windows: on `main`, `verify-system.ps1` passes
- [ ] Remote `windows`, `wsl` and integration branches deleted (owner approved at the time)
- [ ] Root guides no longer mention platform branches
