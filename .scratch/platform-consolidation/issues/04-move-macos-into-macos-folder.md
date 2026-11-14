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

**Status:** done (`be8255a` move, `4800e79` path fixes, on `main`)

- [x] One move commit; `git log --follow` on a moved file reaches pre-move commits
- [x] The link check from ticket 03 passes against `macos/`
- [x] No link in `$HOME` points to a vanished path in the checkout
- [x] The Python tests pass from `macos/`
- [x] A new shell, tmux, LazyGit and the status line start without errors
- [x] No path in the macOS config hard-codes the old checkout layout (tmux base include, the update-system alias, skill READMEs, the gh wrapper comment)
- [x] Pushed

## Outcome

- The move is `be8255a`, made up only of exact renames plus the root
  `.gitignore` paths. The path fixes are a separate commit, `4800e79`, so small
  files such as the tmux configs keep exact renames and `--follow` works.
- tmux includes `~/.tmux/base.conf`, a new declared link, so the config no
  longer names the checkout. The `update-system` alias resolves from `.zshrc`'s
  real location.
- The tracked edit-prose links into `~/workspace/personal/humanizer` needed one
  more `../` after the move.
- Stow packages were unstowed before the move and restowed from `macos/`. The
  `.skill-sync/` state moved to `macos/.skill-sync/`.
- The root now holds only `.gitignore` and `.codegraph/.gitignore`. Ticket 06
  brings the root guides.
- `test_theme_extras` still fails, as it did before this ticket (see 03).
