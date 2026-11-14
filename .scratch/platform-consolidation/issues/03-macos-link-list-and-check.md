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

**Status:** done (`277d708` on `main`)

- [x] Every live link into the checkout is in the list, and nothing else is
- [x] The check passes now and fails when a declared link is broken or missing
- [x] The check can also create missing links from the list (used by ticket 04)
- [x] LazyGit `state.yml` is untracked and ignored; LazyGit still works
- [x] Existing Python tests still pass

## Outcome

- The live count was 63 hand-made links, not 17: Neovim and Ghostty are linked
  file by file. Links into the Stow packages `agents/` and `claude/` (skills,
  the Claude status line, `general-purpose.md`) are owned by
  `scripts/update-skills` and are not listed; the check ignores them.
- Seven dangling links whose sources had left the repo were removed from
  `$HOME` (Starship macchiato, wezterm, `~/.config/lazygit`, two Ghostty themes).
- Superfile's `firstUseCheck`, `lastCheckVersion`, `themeFileVersion` and its
  log were untracked with LazyGit `state.yml`.
- The undeclared-link scan covers `$HOME` and directories holding a declared
  link, without recursion.
- Pre-existing, not fixed here: `scripts/test_theme_extras.py` fails on `main`
  because `051b2f3` hand-edited the vendored Dark 2026 LazyGit theme
  (`authorColors` indentation). Ticket 05 or 08 should restore the drift test.
