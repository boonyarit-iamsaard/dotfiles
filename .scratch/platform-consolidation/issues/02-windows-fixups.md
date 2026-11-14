# 02: Windows fixes

**What to build:** The Windows folder is consistent after its move, before its
history is rewritten in ticket 06. The three files that lost their executable
bit in the move (the gh-agent wrapper, the docker-cleanup script, the Consolas
font patcher) are executable again. The Windows README's lazygit link-target
example and its link to the removed handoff point at current locations. The
machine notes from the handoff (local `http.sslBackend=openssl` because Schannel
failed in automation; Git is system-wide under `C:\Program Files\Git`, do not
add a second Git without reviewing `PATH`) live in the Windows docs. The
variable that now holds the platform folder is named for it (`$platformRoot`)
across the profile and scripts, distinct from the checkout root.

**Blocked by:** None (can start immediately).

**Where:** Windows machine only.

**Status:** ready-for-agent

- [ ] The three files are mode 755 in git
- [ ] The Windows README has no pre-move paths and no link to the handoff
- [ ] Both machine notes are in the Windows docs
- [ ] No Windows script uses one name for both the platform folder and the checkout root
- [ ] `verify-system.ps1` and every `test-*.ps1` pass
- [ ] Pushed to the integration branch
