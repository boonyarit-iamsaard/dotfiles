# Dotfiles

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
mkdir -p ~/.local/bin ~/.config/gh-agent
ln -s ../../dotfiles/.local/bin/gh ~/.local/bin/gh
ln -s dotfiles/.zshenv ~/.zshenv
# ~/.zprofile is not tracked here (Docker, Homebrew and nvm edit it); append once:
printf '\npath=("$HOME/.local/bin" ${path:#$HOME/.local/bin})\n' >> ~/.zprofile
(umask 077; cat > ~/.config/gh-agent/token)   # paste token, Enter, Ctrl-D
~/.local/bin/gh api user --jq .login          # must print the token owner; PATH reloads in a new terminal
```

Create the token under GitHub → Settings → Developer settings → Fine-grained
tokens for the owner account, scoped to the `bookkeeping` repository only:
Contents and Pull requests read/write, Actions and Commit statuses read-only,
everything else none. The token file lives outside this repo and must never be
committed.

## Shared agent skills

Matt Pocock's engineering and productivity skills are read from the clean,
read-only checkout at `~/workspace/personal/skills`. Run the synchronizer on
demand to fast-forward that checkout from its existing tracked remote and
reconcile both Agent Skills consumers:

```bash
~/dotfiles/scripts/update-skills
```

The command never commits or pushes. It refuses to pull a checkout with local
changes and uses `git pull --ff-only`.

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
keeps the local `commit-message` and `typescript-object-composition` skills.
The obsolete Matt skills `diagnose`, `to-issues`, `to-prd`, and `zoom-out` are
archived during migration. A failed migration restores moved package copies
and attempts to restore the previous Stow layout.

After migration, dotfiles and GNU Stow own local skills while the synchronizer
owns direct links from `~/.agents/skills` and `~/.claude/skills` to the
read-only checkout. This keeps the dotfiles repository clean when Matt adds or
removes a skill.
