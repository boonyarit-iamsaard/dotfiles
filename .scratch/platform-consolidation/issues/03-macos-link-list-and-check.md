# 03: macOS link list and check, in the current layout

**What to build:** The Mac's managed links are declared, not remembered. A
committed list names every live link from `$HOME` into the checkout (today 17:
zsh, tmux and its themes, `.ideavimrc`, docker-cleanup, lazygit, lazydocker,
superfile, Starship themes, the gh wrapper, the Claude status line), and a check
script confirms each declared link exists and resolves to its declared source,
and reports links into the checkout that are missing from the list. The check
passes against today's layout, so it is proven before ticket 04 moves anything.
Tool-written runtime state (LazyGit `state.yml`) stops being tracked and is
ignored.

**Blocked by:** None (can start immediately).

**Where:** This Mac, in the live checkout on `main`.

**Status:** ready-for-agent

- [ ] Every live link into the checkout is in the list, and nothing else is
- [ ] The check passes now and fails when a declared link is broken or missing
- [ ] The check can also create missing links from the list (used by ticket 04)
- [ ] LazyGit `state.yml` is untracked and ignored; LazyGit still works
- [ ] Existing Python tests still pass
