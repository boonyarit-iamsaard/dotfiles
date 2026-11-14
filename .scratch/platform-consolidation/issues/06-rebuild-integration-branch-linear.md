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

**Status:** ready-for-agent

- [ ] Before: Windows and WSL have pushed everything and stopped committing
- [ ] Archive tags `archive/windows`, `archive/wsl`, `archive/restructure` pushed at the old tips
- [ ] No merge commits; `main` is an ancestor of the new tip
- [ ] `windows/` is byte-identical to the old integration branch's `windows/`
- [ ] `wsl/` is byte-identical to the `wsl` branch's tree
- [ ] Root tooling and root guides match the old integration branch
- [ ] `git log --follow` on a file in `windows/` and in `wsl/` reaches its first commit
- [ ] Integration branch force-pushed (owner approved)
- [ ] Windows machine: fetch, `git reset --hard` to the new branch, `verify-system.ps1` passes
- [ ] Mac: live checkout switched to the integration branch; link check passes
