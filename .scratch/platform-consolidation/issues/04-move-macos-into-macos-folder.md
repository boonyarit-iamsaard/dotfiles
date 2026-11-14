# 04: Move macOS into `macos/`

**What to build:** Everything macOS-specific lives under `macos/`, moved with
`git mv` in one commit on `main` so history follows. Paths the scripts, tests
and link list assume are updated; every live link is rebuilt from the list to
point into `macos/`, and the Mac keeps working: shell, tmux, LazyGit,
LazyDocker, superfile, Starship, the gh wrapper, the Claude status line, and
the skill sync. Nothing remains at the root except what ticket 06 expects to
become repository tooling.

**Blocked by:** 03

**Where:** This Mac, in the live checkout on `main`.

**Status:** ready-for-agent

- [ ] One move commit; `git log --follow` on a moved file reaches pre-move commits
- [ ] The link check from ticket 03 passes against `macos/`
- [ ] No link in `$HOME` points to a vanished path in the checkout
- [ ] The Python tests pass from `macos/`
- [ ] A new shell, tmux, LazyGit and the status line start without errors
- [ ] No path in the macOS config hard-codes the old checkout layout (tmux base include, the update-system alias, skill READMEs, the gh wrapper comment)
- [ ] Pushed
