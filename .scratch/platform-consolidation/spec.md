# Spec: Platform consolidation

**Status:** ready-for-agent

Replaces the root `HANDOFF.md`. Rules that outlive this migration move to the
root `AGENTS.md`; the work itself lives in this spec and the tickets under
`issues/`.

## Problem Statement

My dotfiles live on three branches that are never merged: `main` (macOS), `wsl`
(WSL), and `windows` (native Windows). `main` shares no history with the other
two, and `windows` forked from `wsl`. The same things are configured three times
— themes for terminals, prompts, LazyGit, LazyDocker and tmux; the LazyGit base
config; btop; `.ideavimrc`; agent instructions and skills — so a change on one
machine never reaches the others, the copies drift, and I cannot see them side
by side to know what is actually shared.

## Solution

One tree with one folder per platform — `windows/`, `wsl/`, `macos/` — and
repository tooling at the root. Each platform branch moves into its folder on
its own machine and is verified against that machine's live links. The
integration branch `restructure/platform-folders` is one straight line with no
merge commits: `main` unchanged, then the Windows and WSL histories rewritten
into their folders and replayed on top. Once all three are in, what they share
is extracted into `shared/`. Finally `main` fast-forwards to the integration
branch, and every machine tracks `main` while using only its own platform
folder.

Roadmap:

1. Move every platform into the integration branch (Windows done; macOS on the
   macOS machine, then Default Dark Modern made active there; Windows and WSL
   histories replayed; WSL verified on the WSL machine).
2. Extract shared pieces into `shared/`, only after all three are in.
3. Fast-forward `main` to the integration branch; every machine uses `main`.

## User Stories

1. As the dotfiles owner, I want one checkout holding every platform's setup, so
   that I can see and compare all platforms' config side by side.
2. As the dotfiles owner, I want each platform's setup in its own top-level
   folder, so that a platform's files are never mixed with another's.
3. As the dotfiles owner, I want repository tooling (Prettier config, pinned
   pnpm, `.gitattributes`, `.gitignore`) at the root, so that one formatting and
   attribute policy applies to every platform.
4. As the dotfiles owner, I want root files treated as belonging to every
   platform, so that any machine may fix them.
5. As the dotfiles owner, I want platform-specific work done only on that
   platform's own machine, so that every change is verified where its live links
   and tools exist.
6. As an agent on one platform, I want to file a ticket instead of editing
   another platform's folder, so that a problem I spot is not lost and is fixed
   where it can be verified.
7. As the dotfiles owner, I want `.scratch/` ignored by default and tracked only
   for research, issues and tickets (or when I say so), so that agent scratch
   space does not leak into the tree.
8. As the dotfiles owner, I want each branch's history preserved through the
   move, so that `git log --follow` still traces a file to before it moved.
9. As the dotfiles owner, I want `main` to remain an ancestor of the integration
   branch, so that switching `main` over is a true fast-forward, never a rewrite.
10. As the dotfiles owner, I want the combined history to be one straight line
    with no merge commits, so that it reads simply.
11. As the dotfiles owner, I want the macOS move to relink every live link on
    the Mac and prove each resolves, so that my shell, tmux, LazyGit,
    LazyDocker, superfile, Starship, gh wrapper and Claude status line keep
    working.
12. As the dotfiles owner, I want Default Dark Modern active in Ghostty, tmux,
    LazyGit, LazyDocker, btop, superfile and Neovim on the Mac once it lives in
    `macos/`, so that every terminal tool matches.
13. As the dotfiles owner, I want macOS's managed links declared in a committed
    list with a check script, so that the next move or a fresh Mac does not
    rely on memory.
14. As the dotfiles owner, I want the WSL move to restow its packages from
    `wsl/` and pass its checks, so that WSL keeps working after the move.
15. As the dotfiles owner, I want the Windows folder's leftovers from its move
    fixed on Windows (lost executable bits, stale paths, the removed handoff
    link, machine notes), so that the Windows setup is consistent before its
    history is rewritten.
16. As the dotfiles owner, I want machine state that the tools write at runtime
    (LazyGit's `state.yml`) kept out of the tree, so that every machine does not
    produce constant dirty diffs.
17. As the dotfiles owner, I want root files from each platform
    (`README.md`, `AGENTS.md`, `.gitignore`, `.markdownlint.json`,
    `GLOSSARY.md`, `docs/`) combined deliberately, so that the root guides
    describe all three platforms.
18. As the dotfiles owner, I want the existing per-platform test suites to keep
    passing from their new folders, so that path assumptions broken by the move
    are caught.
19. As the dotfiles owner, I want theme definitions shared across platforms
    once all are in one tree, so that changing a theme does not mean editing three
    copies.
20. As the dotfiles owner, I want theme sharing to respect ADR-0001 (palette
    owned upstream, theme extras vendored at a pin), so that there is still
    exactly one Dark 2026 palette.
21. As the dotfiles owner, I want identical non-theme config (LazyGit base,
    btop, `.ideavimrc`, agent global instructions, shared and vendored skills)
    extracted into `shared/`, so that each lives once.
22. As the dotfiles owner, I want each machine's `~/.gitconfig` essentials (such
    as `core.symlinks`) managed by that platform's links, so that symlinked
    `CLAUDE.md` files work on a fresh machine.
23. As the dotfiles owner, I want every machine to end up tracking `main`, so
    that there is one branch to pull everywhere.
24. As an agent, I want the rules that outlive this migration in the root
    `AGENTS.md`, so that I follow them after this spec is closed.

## Implementation Decisions

- **Layout.** Top-level folders `windows/`, `wsl/`, `macos/`, later `shared/`.
  The root keeps repository tooling, the agent skill docs, and root guides
  (`README.md`, `AGENTS.md`, `CLAUDE.md` symlink). Platform folders carry their
  own `AGENTS.md` with a `CLAUDE.md` symlink beside it.
- **Integration branch.** `restructure/platform-folders` collects every
  platform. `main` survives as the default branch name; it is fast-forwarded to
  the integration branch at the end.
- **Linear history, no merge commits.** The integration branch is rebuilt as
  one line: `main` unchanged as the base, then the Windows and WSL histories
  rewritten so their files always lived in `windows/` and `wsl/`, replayed with
  their original message, author and date and interleaved by date (each line
  keeps its own order). The commits `windows` and `wsl` share before the fork
  are replayed once, each writing its files into both folders. A final commit
  moves repository tooling back to the root. The rewrite changes history only:
  each folder must come out byte-identical to its source branch, which is why
  it may run from the Mac. Archive tags keep the original commits reachable,
  and the integration branch is force-pushed once.
- **macOS moves on `main`, which stays an ancestor.** The macOS move and the
  Default Dark Modern switch are committed on `main` first, so the replay lands
  on `macos/` with no conflicts. After the rebuild nothing lands on `main` until
  it fast-forwards to the integration branch.
- **Where each checkout sits.** The live macOS checkout stays on `main` through
  the move, so its links keep resolving; integration work before the rebuild
  happens in a separate worktree. After the rebuild the Mac and Windows
  checkouts reset or switch to the integration branch (their platform folders
  are unchanged, so no relinking); WSL switches in its own ticket. Every
  machine switches to `main` after the fast-forward, with no file changes.
- **Platform boundary (hard rule).** Work inside a platform folder runs only on
  that platform's machine. Problems seen from another machine become tickets in
  this tracker. Root files belong to every platform and may be fixed anywhere.
- **macOS link list.** The macOS move introduces a committed declaration of the
  Mac's managed links (target in `$HOME` → source in `macos/`) and a check that
  each declared link exists and resolves to its source, mirroring the Windows
  link manifest and verify script. It is used to relink after the move.
- **Default Dark Modern on macOS.** After the move, Default Dark Modern becomes
  the active macOS theme for Ghostty, tmux, LazyGit, LazyDocker, btop,
  superfile and Neovim; other themes remain alternates. Missing theme files
  (btop, superfile) follow the VS Code Dark Modern definition, and btop comes
  under the macOS link list. ADR-0001 covers only Dark 2026 and is unaffected.
- **Runtime state is ignored.** LazyGit `state.yml` and similar tool-written
  state leave the tree before the rebuild.
- **Shared extraction waits for all three platforms.** Nothing moves into `shared/` until
  all three platforms are in the integration branch, so no file moves twice.
- **Themes follow ADR-0001.** The Dark 2026 palette stays owned by the upstream
  `dark-2026.nvim` repo, with theme extras vendored at the lazy-lock pin. The
  handoff's plan to render every tool's theme from palettes kept in this repo
  (a `build.mjs` over token files) contradicts ADR-0001 and is not adopted. The
  theme ticket opens with a grilling to decide how Windows' hand-ported theme
  files and the other themes (Default Dark Modern, Catppuccin Mocha, One Dark)
  fit the vendored-extras model; superseding ADR-0001 requires a new ADR.
- **LazyGit layering.** LazyGit can stack configs through `LG_CONFIG_FILE`, so
  one shared base plus a theme variant can replace commented theme blocks.
  LazyDocker cannot include files and stays one generated or vendored file per
  theme.
- **Rule documents.** `HANDOFF.md` is deleted. Durable rules (layout, root
  tooling, platform boundary, `CLAUDE.md` symlinks, `.scratch/` opt-in) live in
  the root `AGENTS.md`; the root `README.md` points to the platform folders.

## Testing Decisions

A good check exercises the outcome a person relies on — a link opens the right
file, a test suite passes, history traces back — never the mechanics of how a
move was performed.

- **Live links (highest seam).** On each machine, every managed link into the
  checkout exists and resolves to its expected source after the move. Windows:
  the existing verify script. macOS: the new link list and check script. WSL:
  restow without conflicts plus its existing checks.
- **Existing suites from the new location.** macOS and WSL's Python suites
  (skill sync, theme extras, step runner) and Windows' PowerShell test scripts
  pass when run from their platform folder. These encode repo-root assumptions,
  so they catch paths broken by the move.
- **History.** The integration branch has no merge commits; `main` is an
  ancestor of it before the fast-forward; `windows/` and `wsl/` after the
  rebuild are byte-identical to their source branches; and `git log --follow`
  on a file in any platform folder reaches commits from before the move.
- **Root hygiene.** `pnpm format:check` and `git diff --check` pass at the root
  after any root or Markdown/JSON change.
- **Theme drift.** The existing theme-extras drift test keeps guarding vendored
  extras against their pin after extraction.

Prior art: the Windows link manifest, its verify script and `test-*.ps1`
scripts; the Python `unittest` suites on `main` and `wsl`.

## Out of Scope

- Changing what any tool is configured to do, beyond the paths a move requires.
- Rendering palettes inside this repo (rejected by ADR-0001 unless a new ADR
  supersedes it).
- Installing or replacing Git on Windows (Git is system-wide under
  `C:\Program Files\Git`; do not add a second Git without reviewing `PATH`).
- Editing a platform folder from another platform's machine.

## Further Notes

- `main` has history unrelated to `wsl` and `windows`; `windows` forked from
  `wsl` at `0c5ebe7`.
- `core.symlinks` is enabled globally on Windows, although the Git for Windows
  system config still says `false`.
- The Windows checkout uses local `http.sslBackend=openssl` because Schannel
  failed in the automation environment. This note belongs in the Windows docs.
- The Windows move is on the integration branch already (`546d5f7`); its link
  script replaces a managed link only when the target has vanished and lies
  inside the checkout.
