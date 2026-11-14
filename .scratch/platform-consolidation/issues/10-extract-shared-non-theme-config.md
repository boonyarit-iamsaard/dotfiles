# 10: Extract shared non-theme config into `shared/`

**What to build:** Config that is identical, or should be, across platforms
lives once under `shared/`: the LazyGit base config, btop, `.ideavimrc`, the
agent global instructions, and the shared and vendored skills with one
manifest. Platform-only differences stay in the platform folder. Every
platform's links point at the shared copies.

**Blocked by:** 07

**Where:** `shared/` and root from any machine; each platform's relink on its own machine.

**Status:** ready-for-agent

- [ ] Each listed item exists once under `shared/`, or the ticket records why it stays per platform
- [ ] Skill sync on each platform reads the shared skills
- [ ] Mac: links updated, link check and Python tests pass
- [ ] WSL: restow succeeds, tests pass
- [ ] Windows: links updated, `verify-system.ps1` and `test-*.ps1` pass
