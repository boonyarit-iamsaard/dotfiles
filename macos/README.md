# Dotfiles

## Maintenance

`~/dotfiles/update-system/update-system.sh` updates installed package managers
and shared skills. It leaves pinned Homebrew formulas unchanged. The
`update-system` alias is available in new shells.

It and `docker-cleanup/docker-cleanup.sh` share `scripts/lib/step-runner.zsh`.
Both print a summary and exit 1 when an error-severity step fails; warning-only
failures leave the exit status successful. Docker cleanup removes containers
and unused volumes, networks, and build cache. Its tests use fake executables
and never contact a real Docker daemon or run package updates.

## Links

`links.tsv` declares every hand-made link from `$HOME` into this checkout,
one `target<TAB>source` line each. Links into `agents/` and `claude/` are not
listed: `scripts/update-skills` manages them with Stow. `scripts/check-links`
exits 1 when a declared link is missing, points elsewhere, is a real file, or
its source is gone. It also fails on an undeclared link into the checkout in
`$HOME` itself or in any directory that holds a declared link; other
directories are not searched. `--create` adds missing links as relative
symlinks and never replaces an existing file or link.

Tool-written runtime state (LazyGit `state.yml`, superfile's version stamps) is
ignored by `.gitignore`.

## Themes

Catppuccin remains active. Shared settings and theme variants are separate:

| Tool | Switch |
| --- | --- |
| tmux | Change `@theme` in `.tmux.conf` to `catppuccin`, `dark-2026`, or `default-dark-modern`; restart the server for a clean switch. |
| lazygit | Change the second path in `LG_CONFIG_FILE` in `.zshrc`. Variants live under `Library/Application Support/lazygit/themes/`. |
| lazydocker | Copy the selected variant body into `config.yml` between the theme markers, omitting leading comments. |
| Neovim | Change `colorscheme` in `lua/plugins/colorscheme.lua`; enable the matching `themes.*` import for Dark 2026 or Dark Modern. |

`~/.tmux/themes` links to `~/dotfiles/.tmux/themes`. The existing root tmux
configuration paths continue to work. macOS Application Support paths and the
transparent Neovim floating window are retained.

Dark 2026 extras are vendored byte-for-byte from the plugin revision pinned in
`.config/nvim/lazy-lock.json`. To update them, copy the four upstream extras at
the new pin and run `python3 -m unittest scripts/test_theme_extras.py`. These
files work without depending on Neovim's plugin directory at runtime.

## Agent gh wrapper

`gh` is installed only so agents can handle pull requests; it is never logged
in. `~/.local/bin/gh` (symlink to `~/dotfiles/.local/bin/gh`) reads a
fine-grained token from `~/.config/gh-agent/token` for each call and runs
`/opt/homebrew/bin/gh`, so the token never enters the environment of other
processes. Three files put `~/.local/bin` ahead of Homebrew so the wrapper wins
in every zsh mode: `.zshenv` (for `zsh -c`, which tools spawn), `.zprofile`
(after its `brew shellenv`, for login shells), and `.zshrc` (interactive). A
process started before these changed keeps its old `PATH`; check with
`command -v gh`, or call `~/.local/bin/gh` directly. No account is logged in
to the keyring (`gh auth status` shows none), so a bypassed wrapper or a
missing token file makes `gh` fail with "set the GH_TOKEN environment variable"
instead of acting as another account. To remove a login, run the real binary
without the variable, because the wrapper's `GH_TOKEN` makes `gh auth logout`
refuse: `env -u GH_TOKEN /opt/homebrew/bin/gh auth logout -u <user>`.

Set up on a new Mac, or when the token expires:

```bash
brew install gh
mkdir -p ~/.config/gh-agent
~/dotfiles/scripts/check-links --create       # links ~/.local/bin/gh, ~/.zshenv and the rest
# ~/.zprofile is not tracked here (Docker, Homebrew and nvm edit it); append once:
printf '\npath=("$HOME/.local/bin" ${path:#$HOME/.local/bin})\n' >> ~/.zprofile
(umask 077; cat > ~/.config/gh-agent/token)   # paste token, Enter, Ctrl-D
~/.local/bin/gh api user --jq .login          # must print the token owner; PATH reloads in a new terminal
```

Create the token under GitHub → Settings → Developer settings → Fine-grained
tokens for the owner account, scoped to the `bookkeeping` repository only:
Contents, Issues and Pull requests read/write, Actions and Commit statuses
read-only, everything else none. Without Issues write, commenting on or editing
an issue fails with "Resource not accessible by personal access token". The
token file lives outside this repo and must never be committed.

`gh project ...` reads `~/.config/gh-agent/project-token` instead of the default
token file, so project access can use a separately scoped token. Other commands
keep using `~/.config/gh-agent/token`.

## Shared agent skills

The personal skills `commit-message`, `edit-prose`, `typescript-house-style`,
and `runbook` are tracked for both Claude and Codex. The old
`typescript-object-composition` link is retired automatically. The updater
creates missing personal directory links, checks their resources, and preserves
installer-owned skills such as Impeccable.

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
~/dotfiles/scripts/update-skills
```

The command never commits or pushes. It checks both the skills and Humanizer
checkouts for local changes before any pull and uses `git pull --ff-only`.
Matt's live catalogs are `ENGINEERING.md` and `PRODUCTIVITY.md` in each consumer;
the package README points there instead of keeping a stale copied catalog.

Preview or diagnose reconciliation with:

```bash
~/dotfiles/scripts/update-skills --dry-run
~/dotfiles/scripts/update-skills --check
```

### One-time migration

The first conversion from copied skills must be previewed before it is run:

```bash
~/dotfiles/scripts/update-skills --dry-run --migrate
~/dotfiles/scripts/update-skills --migrate
```

Migration accepts only files whose Git blobs can be traced to the skills
checkout's history. It snapshots both dotfiles skill packages under
`~/.local/state/dotfiles-skills/backups`, archives verified Matt copies, and
keeps the four personal skills listed above.
The obsolete Matt skills `diagnose`, `to-issues`, `to-prd`, and `zoom-out` are
archived during migration. A failed migration restores moved package copies
and attempts to restore the previous Stow layout.

After migration, personal skills link to their dotfiles directories while Matt's
skills link directly to the read-only checkout. The synchronizer retires deleted
upstream links, including broken ones, and refuses unexpected package copies.
`--migrate` can archive retired skills verified against upstream Git history;
it checks every file and restores moved package copies if migration fails.

Run the maintenance, synchronization, and theme checks with:

```bash
python3 -m unittest scripts/test_update_skills.py scripts/test_step_runner.py scripts/test_theme_extras.py
```
