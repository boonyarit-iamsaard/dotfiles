# 06: Rebuild the integration branch linearly on `main`

**What to build:** `restructure/platform-folders` becomes one straight line with
no merge commits: `main` unchanged (including ticket 04's move and ticket 05's theme switch), then the
Windows and WSL histories rewritten so their files always lived in `windows/`
and `wsl/`. The 202 commits shared before `windows` forked from `wsl`
(`0c5ebe7`) are each replayed once, writing their files into both folders;
later commits touch only their own folder. Replayed commits keep message,
author and date, and are interleaved by date while each line keeps its own
order. A final commit moves repository tooling from `windows/` back to the
root. This is a history-only change: no file content changes, so it may run
from the Mac.

**Blocked by:** 01, 02, 05

**Where:** This Mac (history only), in a worktree; then each machine.

**Status:** in progress (rebuilt as `4be8872`; Windows reset pending)

- [x] Before: Windows and WSL have pushed everything and stopped committing
- [x] Archive tags `archive/windows`, `archive/wsl`, `archive/restructure` pushed at the old tips
- [x] No merge commits; `main` is an ancestor of the new tip
- [x] `windows/` is byte-identical to the old integration branch's `windows/`
- [x] `wsl/` is byte-identical to the `wsl` branch's tree
- [x] Root tooling and root guides match the old integration branch
- [x] `git log --follow` on a file in `windows/` and in `wsl/` reaches its first commit
- [x] Integration branch force-pushed (owner approved)
- [ ] Windows machine: `git fetch`, then `git reset --hard origin/restructure/platform-folders` (the rebuilt integration branch); `verify-system.ps1` passes
- [x] Mac: live checkout switched to the integration branch; link check passes

## Outcome

- Rebuilt with git plumbing (`mktree`, `commit-tree`) by
  `.scratch/platform-consolidation/rebuild.py` in the `~/dotfiles-restructure`
  worktree (untracked). Every tree is assembled from its source commit's tree,
  so there were no conflicts to resolve.
- 285 commits on `main` (`c341baa`): 202 shared, 41 Windows-line, 41 WSL-line,
  and one new commit. Author, committer, dates and message bytes are kept for
  every replay except one.
- The tooling move is the replay of `546d5f7`, not a final commit: the later
  integration commits edit root files, so the tooling has to be at the root
  before them. Its message is now "refactor: move repository tooling from
  windows/ to the root"; author and date are unchanged.
- The new last commit combines the Windows and macOS root `.gitignore`. It is
  the only root file that differs from the old integration branch.
- `git log --follow` reaches each file's first commit (214 files checked,
  vendored payloads skipped). For 35 files that began as ports of macOS files,
  copy detection then continues into macOS history.
- WSL commit signatures are dropped in the rewrite. The archive tags keep the
  originals, and hashes for Windows-line commits cited in older tickets
  (for example `aba1c7d`) now resolve only through them.
- Archive tags: `archive/windows` `5c7b5b4`, `archive/wsl` `8f8f05a`,
  `archive/restructure` `680cf71`.
- Mac: `~/dotfiles` is on the integration branch; `check-links` reports 67 ok.
- Follow-up: the root README still lists `macos/` and `wsl/` as planned.
