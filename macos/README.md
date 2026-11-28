# Dotfiles

## Maintenance

`~/dotfiles/macos/update-system/update-system.sh` updates installed package
managers and shared skills. It leaves pinned Homebrew formulas unchanged. The
`update-system` alias is available in new shells.

It and `docker-cleanup/docker-cleanup.sh` share `scripts/lib/step-runner.zsh`.
Both print a summary and exit 1 when an error-severity step fails; warning-only
failures leave the exit status successful. Docker cleanup removes containers and
unused volumes, networks, and build cache. Its tests use fake executables and
never contact a real Docker daemon or run package updates.

## Links

`links.tsv` declares every hand-made link from `$HOME` into this checkout, one
`target<TAB>source` line each. Links into `agents/` and `claude/` are not
listed: `scripts/update-skills` manages them with Stow. `scripts/check-links`
exits 1 when a declared link is missing, points elsewhere, is a real file, or
its source is gone. It also fails on an undeclared link into the checkout in
`$HOME` itself or in any directory that holds a declared link; other directories
are not searched. `--create` adds missing links as relative symlinks and never
replaces an existing file or link.

A source may itself be a symlink out of `macos/`: `.ideavimrc` and
`.config/lazygit/config.yml` link to their copies in [`shared/`](../shared/).
The check passes when the whole chain resolves and reports `no-source` when it
does not.

`.zshenv` sets `XDG_CONFIG_HOME` to `~/.config`, so lazygit, lazydocker and
superfile read their config there, as on WSL, instead of
`~/Library/Application Support`. superfile keeps its state (pinned folders,
toggles, version stamps, log) in `~/Library/Application Support/superfile`,
outside the repo.

LazyGit's `state.yml` is ignored by `.gitignore`. `~/.config/lazydocker` and
`~/.config/superfile` are real folders, so what those tools write stays out of
the checkout; `links.tsv` links only the theme files and superfile's
`hotkeys.toml` into them.

## Git config

`links.tsv` links `~/.gitconfig` to `.gitconfig` here. It includes
`~/dotfiles/shared/gitconfig` for the shared essentials (`core.symlinks=true`),
then `~/.gitconfig.local` for identity, signing, and machine-only settings. The
checkout must live at `~/dotfiles`.

On an existing Mac, `check-links` reports `not-a-link: .gitconfig` until the
unmanaged config moves aside. If `~/.gitconfig.local` already exists, merge the
settings into it first; do not overwrite it:

```bash
# One-time migration, only when ~/.gitconfig.local does not already exist:
mv -n ~/.gitconfig ~/.gitconfig.local
~/dotfiles/macos/scripts/check-links --create
git config --show-origin --get core.symlinks   # must name shared/gitconfig
```

On a fresh Mac, `check-links --create` adds the link; then put personal settings
in the local file:

```bash
git config --file ~/.gitconfig.local user.name "Your Name"
git config --file ~/.gitconfig.local user.email "you@example.com"
```

Use `--file ~/.gitconfig.local` for local settings instead of `--global`, which
writes to the tracked `.gitconfig`. Local settings are loaded last and can
override the shared defaults. Keep `core.symlinks=true` so `CLAUDE.md` checks
out as a link. `git config --global --list` skips includes; add `--includes` to
see the merged settings.

## Themes

starship, lazygit, tmux, Ghostty, lazydocker and superfile follow this Mac's
active theme, chosen with `set-theme` and saved outside the checkout (see
[ADR 0004](../docs/adr/0004-active-theme-local-per-machine.md)). The other tools
in the table below still run Catppuccin Mocha from tracked config;
`ActiveThemeScopeTest` in `scripts/test_theme_extras.py` fails when one of them
is not on Mocha. Catppuccin Macchiato, Catppuccin Mocha, Dark 2026 and Default
Dark Modern are available.

```bash
~/dotfiles/macos/scripts/check-links --create # links ~/.local/bin/set-theme
set-theme --list                # complete themes; * marks the active one
set-theme dark-2026             # check, apply, then save the choice
set-theme                       # reapply the saved theme, or Catppuccin Macchiato
set-theme --check               # report tools that do not use the active theme
```

On a Mac that still links `~/.config/lazydocker` or `~/.config/superfile` whole
into this folder, run `~/dotfiles/macos/scripts/set-theme` (it works before a
new shell loads the `set-theme` link) to replace them with real folders, then
`check-links --create` again to link the theme files into them.

The choice is saved in `${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/theme`;
with none saved, Catppuccin Macchiato is used. `.zshrc` names no theme: it reads
`set-theme --env`, which warns and uses the default when the saved theme is
unknown or incomplete. Open a new shell, reload Ghostty and restart the tmux
server after a switch. The btop, lazydocker, lazygit, Neovim and tmux theme
folders here are links into [`shared/themes/`](../shared/themes/README.md);
Ghostty and superfile keep their themes in this folder. Settings and theme
variants are separate:

| Tool       | Switch                                                                                                                                                                                                                                            |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Ghostty    | `set-theme`; generates `~/.config/ghostty/config` from `.config/ghostty/base` plus the `theme` line; variants live under `.config/ghostty/themes/`.                                                                                               |
| tmux       | `set-theme`; generates `~/.tmux.conf` with `@theme` and the `~/.tmux/base.conf` include (Mocha keeps the file name `catppuccin.conf`); restart the server for a clean switch.                                                                     |
| lazygit    | `set-theme`; shell startup sets `LG_CONFIG_FILE` to `config.yml` followed by the variant under `.config/lazygit/themes/`.                                                                                                                         |
| lazydocker | `set-theme`; generates `~/.config/lazydocker/config.yml` from `.config/lazydocker/base.yml` with the variant body, minus its leading comments, between the theme markers.                                                                         |
| Neovim     | Change `colorscheme` in the LazyVim opts in `lua/plugins/colorscheme.lua`; Catppuccin Mocha is active. Keep exactly one `themes.*` import uncommented to match it: `themes.catppuccin-mocha`, `themes.dark-2026` or `themes.default-dark-modern`. |
| superfile  | `set-theme`; generates `~/.config/superfile/config.toml` from `.config/superfile/base.toml` plus the `theme` line; variants live under `.config/superfile/theme/`.                                                                                |
| btop       | Change `color_theme` in `.config/btop/btop.conf`; only the linked themes in `.config/btop/themes/` are managed.                                                                                                                                   |
| starship   | `set-theme`; shell startup sets `STARSHIP_CONFIG` to `.config/starship.<name>.toml`, linked from `shared/themes/starship/` (Dark 2026 lives in this folder).                                                                                      |

`~/.tmux/base.conf` and `~/.tmux/themes` link into `.tmux/` here, so the
generated `~/.tmux.conf` includes them without naming the checkout.

`set-theme` owns `~/.tmux.conf`, `~/.config/ghostty/config`,
`~/.config/lazydocker/config.yml` and `~/.config/superfile/config.toml`: their
first line says edits are overwritten, so put lasting settings in the tracked
base. It replaces the old links from those paths, or from the whole
`~/.config/lazydocker` and `~/.config/superfile` folders, into this folder with
real ones before it writes beneath them, and refuses any other link or file
there, or a parent folder that leads into the checkout, with "move it aside"
before it writes anything.

Ghostty sets `background-opacity` to 0.8 with a 20 blur radius. Neovim's
Catppuccin Mocha uses `transparent_background` and transparent floats, so its
backgrounds show the Ghostty background through. lazygit and lazydocker set no
background, so they show it through already. The tmux themes' status line and
pane styles use the default background, so tmux is transparent too.

btop saves its settings on exit, so changing options inside btop edits the
tracked `btop.conf`.

Dark 2026 extras in `shared/themes/` are vendored byte-for-byte from the plugin
revision pinned in `.config/nvim/lazy-lock.json`, which must match the WSL pin.
To update them, follow
[Refresh a vendored file](../shared/themes/README.md#refresh-a-vendored-file)
and run `python3 -m unittest scripts/test_theme_extras.py`. These files work
without depending on Neovim's plugin directory at runtime.

superfile's Catppuccin themes are superfile's own, pinned byte-for-byte in
`.config/superfile/upstream.json` and checked by `scripts/test_theme_extras.py`;
Dark 2026 and Default Dark Modern are hand ports that name the VS Code key
behind each colour. superfile's bundled themes land in the real
`~/.config/superfile/theme/`, not here.

## Agent gh wrapper

`gh` is installed only so agents can handle issues and pull requests; it is
never logged in. `~/.local/bin/gh` (symlink to `~/dotfiles/macos/.local/bin/gh`)
reads a fine-grained token from `~/.config/gh-agent/token` for each call and
runs `/opt/homebrew/bin/gh`, so the token never enters the environment of other
processes. Three files put `~/.local/bin` ahead of Homebrew so the wrapper wins
in every zsh mode: `.zshenv` (for `zsh -c`, which tools spawn), `.zprofile`
(after its `brew shellenv`, for login shells), and `.zshrc` (interactive). A
process started before these changed keeps its old `PATH`; check with
`command -v gh`, or call `~/.local/bin/gh` directly. No account is logged in to
the keyring (`gh auth status` shows none), so a bypassed wrapper or a missing
token file makes `gh` fail with "set the GH_TOKEN environment variable" instead
of acting as another account. To remove a login, run the real binary without the
variable, because the wrapper's `GH_TOKEN` makes `gh auth logout` refuse:
`env -u GH_TOKEN /opt/homebrew/bin/gh auth logout -u <user>`.

Set up on a new Mac, or when the token expires:

```bash
brew install gh
mkdir -p ~/.config/gh-agent
~/dotfiles/macos/scripts/check-links --create # links ~/.local/bin/gh, ~/.zshenv and the rest
# ~/.zprofile is not tracked here (Docker, Homebrew and nvm edit it); append once:
printf '\npath=("$HOME/.local/bin" ${path:#$HOME/.local/bin})\n' >> ~/.zprofile
(umask 077; cat > ~/.config/gh-agent/token)   # paste token, Enter, Ctrl-D
~/.local/bin/gh api user --jq .login          # must print the token owner; PATH reloads in a new terminal
```

Create the token under GitHub → Settings → Developer settings → Fine-grained
tokens for the owner account, scoped to the `bookkeeping`, `dotfiles` and
`foundry` repositories only: Contents, Issues and Pull requests read/write,
Actions and Commit statuses read-only, everything else none. Without Issues
write, commenting on or editing an issue fails with "Resource not accessible by
personal access token". The token file lives outside this repo and must never be
committed.

`gh project ...` reads `~/.config/gh-agent/project-token` instead of the default
token file, so project access can use a separately scoped token. Other commands
keep using `~/.config/gh-agent/token`.

## Shared agent skills

Personal and vendored skills come from
[`shared/skills/skills.json`](../shared/skills/skills.json) (see
[shared/skills/README.md](../shared/skills/README.md)). Each skill the manifest
gives a consumer is a relative symlink in that consumer's Stow package
(`agents/.agents/skills/` or `claude/.claude/skills/`) into `shared/skills/`.
The updater links each live skill to its package entry, checks its resources,
and fails when a package entry is a real copy or links somewhere other than its
manifest source. The old `typescript-object-composition` link is retired
automatically.

Impeccable's Claude Code subagents are linked the same way from
`claude/.claude/agents/`; Stow installs them:

```bash
stow --dir=$HOME/dotfiles/macos --target=$HOME -S claude agents
```

Ponytail's session hook and slash commands come from its Claude Code plugin,
pinned in the manifest. `scripts/sync-agent-plugins` pins its marketplace to
that ref, then installs and updates it; `update-system` runs it after the skills
updater:

```bash
~/dotfiles/macos/scripts/sync-agent-plugins
```

A Mac that installed Impeccable with `npx impeccable` has real copies at
`~/.claude/skills/impeccable` and `~/.claude/agents/impeccable-*.md`. Move them
out before the first sync; the updater refuses to replace them:

```bash
backup=~/.local/state/dotfiles-skills/backups/$(date +%Y%m%d-%H%M%S)-installer-impeccable
mkdir -p "$backup/agents"
mv ~/.claude/skills/impeccable "$backup/skill"
mv ~/.claude/agents/impeccable-*.md "$backup/agents/"
```

Never run `npx impeccable update` in the home directory: it writes over the
managed links.

`edit-prose` layers house rules over the MIT-licensed Humanizer rules. On a new
machine, clone its supporting checkout before syncing:

```bash
git clone https://github.com/blader/humanizer.git ~/workspace/personal/humanizer
```

Matt Pocock's engineering and productivity skills are read from the clean,
read-only checkout at `~/workspace/personal/skills`. Run the synchronizer on
demand to fast-forward that checkout from its existing tracked remote and
reconcile both Agent Skills consumers:

```bash
~/dotfiles/macos/scripts/update-skills
```

The command never commits or pushes. It checks both the skills and Humanizer
checkouts for local changes before any pull and uses `git pull --ff-only`.
Matt's live catalogs are `ENGINEERING.md` and `PRODUCTIVITY.md` in each
consumer; the package README points there instead of keeping a stale copied
catalog.

Preview or diagnose reconciliation with:

```bash
~/dotfiles/macos/scripts/update-skills --dry-run
~/dotfiles/macos/scripts/update-skills --check
```

### One-time migration

The first conversion from copied skills must be previewed before it is run:

```bash
~/dotfiles/macos/scripts/update-skills --dry-run --migrate
~/dotfiles/macos/scripts/update-skills --migrate
```

Migration accepts only files whose Git blobs can be traced to the skills
checkout's history. It snapshots both dotfiles skill packages under
`~/.local/state/dotfiles-skills/backups`, archives verified Matt copies, and
keeps the personal and vendored skills the manifest declares. The obsolete Matt
skills `diagnose`, `to-issues`, `to-prd`, and `zoom-out` are archived during
migration. A failed migration restores moved package copies and attempts to
restore the previous Stow layout.

After migration, manifest skills link into `shared/skills/` while Matt's skills
link directly to the read-only checkout. The synchronizer retires deleted
upstream links, including broken ones, and refuses unexpected package copies.
`--migrate` can archive retired skills verified against upstream Git history; it
checks every file and restores moved package copies if migration fails.

Run the maintenance, synchronization, link, and theme checks from `macos/` with:

```bash
python3 -m unittest discover -s scripts -p 'test_*.py'
```
