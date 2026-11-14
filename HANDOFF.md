# Platform consolidation handoff

Read the root [AGENTS.md](AGENTS.md) before making changes. This replaces the
original Windows setup handoff, whose "independent branches that are never
merged" decision no longer holds.

## Goal

Combine the three platform branches into one tree with one folder per platform,
then extract what they share (theme tokens first) into `shared/`.

| Branch    | Platform       | Status                                      |
| --------- | -------------- | ------------------------------------------- |
| `windows` | Native Windows | Moved into `windows/`                       |
| `wsl`     | WSL (Linux)    | To move into `wsl/`, on the WSL machine     |
| `main`    | macOS          | To move into `macos/`, on the macOS machine |

`main` has history unrelated to the other two; `windows` forked from `wsl` at
`0c5ebe7`.

## Decisions

- **One folder per platform:** `windows/`, `wsl/`, `macos/`. Repository tooling
  (`package.json`, Prettier config, `.gitattributes`, `.gitignore`) and the
  agent skill docs (`docs/agents/`) stay at the root.
- **Move on each platform's own machine.** Each move must relink that machine's
  live config, so it is done and verified where the links live.
- **Preserve history.** On each branch, `git mv` everything into its platform
  folder and commit. Then merge the branches with
  `git merge --allow-unrelated-histories`. The trees are disjoint, so only root
  files (`README.md`, `AGENTS.md`, `.gitignore`) conflict, and
  `git log --follow` keeps working.
- **Extract shared pieces after the merge, not before.** Moving a file twice is
  noise; once every platform is in one tree, the duplicates are visible side by
  side.
- **`CLAUDE.md` is a symlink to the `AGENTS.md` beside it.** `core.symlinks` is
  enabled globally (the Git for Windows system config still says `false`).
- **`.scratch/` is ignored.** Tracking anything there is opt-in with
  `git add -f`.

## Windows move (done on `restructure/platform-folders`)

- Everything Windows-specific moved into `windows/`; the root keeps tooling,
  `docs/agents/`, and the root guides.
- `windows/scripts/link-dotfiles.ps1` now replaces a link only when its target
  no longer exists and lies inside the checkout. That is how the moved sources
  were relinked; links that resolve, or point elsewhere, are still refused.
- The skill reconciler re-pointed skill links from its recorded state without
  changes.
- `gh-agent\bin` moved to `windows\gh-agent\bin` in the environment manifest and
  the PowerShell profile.
- `set-node-toolchain.ps1` reads the root `package.json`.
- `verify-system.ps1` checks the `windows` folder instead of the branch name.

## Next steps

1. **WSL machine:** on `wsl`, `git mv` everything into `wsl/`, keep repository
   tooling at the root, fix paths the Stow packages and scripts assume, restow,
   and verify. Commit there.
2. **macOS machine:** the same on `main`, into `macos/`.
3. **Merge:** on one branch, merge the other two with
   `--allow-unrelated-histories`. Resolve the root `README.md`, `AGENTS.md`, and
   `.gitignore` by hand. Decide which branch name survives as the default.
4. **Extract theme tokens** into `shared/themes/`:
   - `tokens/<theme>.json`, one per theme (Default Dark Modern, Dark 2026,
     Catppuccin Mocha, One Dark): background, foreground, cursor, selection, the
     16 ANSI colors, and UI roles (active/inactive border, selected line,
     accents, git added/removed/modified).
   - `sources/` for upstream references such as `dark-2026.jsonc`.
   - `build.mjs` (Node, already required for Prettier) renders each tool's file:
     Windows Terminal, Oh My Posh, LazyGit, LazyDocker, tmux, Ghostty, and
     Starship. Outputs are committed so no platform builds at install time;
     `--check` fails when an output is stale.
   - LazyGit can layer configs through `LG_CONFIG_FILE`
     (`config.yml,theme.yml`), so one base config plus a theme file can replace
     the commented theme blocks. LazyDocker cannot; it stays fully generated.
5. **Extract other shared config** into `shared/`: identical files such as the
   LazyGit base config, btop, and `.ideavimrc`; the agent global instructions;
   and the vendored and shared skills with one manifest.
6. **Consider managing `~/.gitconfig`** (for example `core.symlinks`) through
   each platform's links.

## Machine notes still true on Windows

- This checkout uses local `http.sslBackend=openssl` because Schannel failed in
  the automation environment.
- Git is installed system-wide under `C:\Program Files\Git`, not by Scoop.
  Decide before migrating; do not install a second Git without reviewing `PATH`
  precedence.
