# Dotfiles

Personal shell and tooling configuration managed with GNU Stow.

## Maintenance scripts

`update-system.sh` and `docker-cleanup.sh` share `scripts/lib/step-runner.zsh`:
each prints a step summary and exits 1 when any error-severity step failed
(warnings don't affect the exit status).

## Themes

Three themes are maintained: default dark modern (active), catppuccin mocha
and dark 2026. Each tool
keeps a shared base config plus one theme variant per theme; switching is a
one-line edit per tool:

| Tool | Switch |
| --- | --- |
| tmux | `set -g @theme …` in `tmux/.tmux.conf` (variants in `tmux/.tmux/themes/`); restart the server for a clean switch |
| lazygit | second path of `LG_CONFIG_FILE` in `zsh/.zshrc` (variants in `config/lazygit/themes/`) |
| lazydocker | replace the block between the `# >>> theme` markers in `config/lazydocker/config.yml` with the body of `config/lazydocker/themes/<name>.yml` |
| Neovim | `colorscheme` in `config/nvim/lua/plugins/colorscheme.lua`; keep exactly one `{ import = "themes.<name>" }` line uncommented for dark 2026 or default dark modern |

The dark 2026 palette is owned by
[dark-2026.nvim](https://github.com/boonyarit-iamsaard/dark-2026.nvim); its
theme extras are vendored byte-for-byte at the commit pinned in
`config/nvim/lazy-lock.json` (see `docs/adr/0001-palette-owned-upstream-extras-vendored.md`).
After bumping the plugin, re-copy each extra from the new pin;
`python3 -m unittest scripts/test_theme_extras.py` fails on any drift.

Default dark modern has no upstream extras; its variants are hand-ported from
VS Code's `theme-defaults/themes/dark_modern.json`.

## Go toolchain

Go is installed with Homebrew and pinned so routine `brew upgrade` runs do not change the local Go version unexpectedly.

Install Go:

```bash
brew install go
brew pin go
go version
```

Shell setup in `~/.zshrc`:

```zsh
# Go
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"
```

Reload shell and verify:

```bash
source ~/.zshrc
mkdir -p "$GOPATH/bin"
which go
go env GOROOT GOPATH
```

Install common Go developer tools:

```bash
go install golang.org/x/tools/gopls@latest
go install github.com/go-delve/delve/cmd/dlv@latest
go install honnef.co/go/tools/cmd/staticcheck@latest
```

Upgrade Go intentionally:

```bash
brew unpin go
brew upgrade go
brew pin go
go version
```

After upgrading Go, refresh Go tools:

```bash
go install golang.org/x/tools/gopls@latest
go install github.com/go-delve/delve/cmd/dlv@latest
go install honnef.co/go/tools/cmd/staticcheck@latest
```

Verify the upgrade against the current project:

```bash
go test ./...
go vet ./...
staticcheck ./...
```

## Java toolchain

Java is managed with SDKMAN. Eclipse Temurin (LTS) and Maven are installed
through SDKMAN and pinned by version so they are not upgraded unexpectedly;
upgrades are performed intentionally, mirroring the Go policy above. The SDKMAN
tool itself is kept current by `update-system.sh`, which also flushes SDKMAN caches.

Install SDKMAN (requires `zip`; `unzip` is already available via Homebrew):

```bash
brew install zip
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
```

Install the JDK and Maven:

```bash
sdk install java 21.0.11-tem   # Eclipse Temurin 21 LTS
sdk install maven 3.9.16
sdk current
```

Shell setup in `~/.zshrc` (this block must remain at the end of the file):

```zsh
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
```

Verify:

```bash
java -version
javac -version
mvn -version
echo "$JAVA_HOME"
```

Upgrade intentionally (for example, to a newer Temurin LTS):

```bash
sdk list java
sdk install java 25.0.3-tem
sdk default java 25.0.3-tem
java -version
```

When configuring IntelliJ or VS Code, point the project SDK at the concrete
version directory rather than the `current` symlink, which moves when the
default version changes. Print the concrete path for an installed version with:

```bash
sdk home java 21.0.11-tem            # prints the concrete installation path
```

List the installed versions (ignoring the `current` symlink) with:

```bash
ls -d ~/.sdkman/candidates/java/*/ | grep -v '/current/$'
```

## Agent skills

Matt Pocock's engineering and productivity skills are maintained in a
read-only checkout at `~/workspace/personal/skills`. The dotfiles packages
contain flattened, relative symlinks to that checkout so Claude Code, Codex,
and other Agent Skills clients see the same skill versions.

Update the checkout and reconcile both consumers with:

```bash
~/dotfiles/scripts/update-skills
```

Use `--dry-run` to preview changes, `--check` in diagnostics, and `--migrate`
only for the initial conversion from copied skills. The updater requires
Python 3 and uses only its standard library. It refuses to pull when the skills
checkout has local changes. Routine reconciliation refuses to replace any real
directory or unmanaged symlink. The one-time `--migrate` mode is deliberately
broader: it matches each Claude `SKILL.md` to its grouped Agents counterpart,
snapshots both complete consumer trees, and then archives the verified copies.

The engineering and productivity source catalogs remain separate and are
linked into each consumer as `ENGINEERING.md` and `PRODUCTIVITY.md`.

### Stow layout

The shared user-level skill directories remain real, while each managed skill
folder is linked as a whole directory so Codex can discover it:

```bash
~/dotfiles/scripts/update-skills
```

The updater creates `~/.agents/skills` and `~/.claude/skills` before the final
Stow operation, preventing Stow from collapsing either shared directory into a
single symlink. It removes the old file-by-file layout and lets Stow fold only
the individual skill directories. Tools that install skills in place (e.g.
`npx impeccable`, which writes to `~/.claude/skills/impeccable`) can therefore
replace only their own leaf directory without taking every skill offline.

`impeccable` is **not** version-controlled (see `.gitignore`) and is excluded
from both Stow packages by their `.stow-local-ignore` files. It is installed
and updated in place by its own tool, which rewrites its files on every update:

```bash
npx impeccable update   # manages ~/.claude/skills/impeccable and ~/.agents/skills/impeccable in place
```

It is freely re-installable, so it lives as plain files alongside the stowed
skills rather than as tracked symlinks. Custom dotfiles skills stay tracked;
routine reconciliation leaves both custom and installer-owned directories
untouched. Migration preserves nonmatching directories and backs up every path
it archives.

### When to re-stow

`npx impeccable update` does **not** require a re-stow — it only rewrites its
own folder. The skills updater re-stows both consumers automatically, including
after a failed run that had already unlinked them. Re-stow
Claude manually only when:

- You add (or rename) a custom skill under `claude/.claude/skills/` and need it
  symlinked into `~/.claude/skills`.
- An installer ever clobbers `~/.claude/skills` itself (the `--no-folding`
  real-directory layout means a single re-stow restores every link).

### Agent plugins

Plugins that ship hooks or commands (currently
[Ponytail](https://github.com/DietrichGebert/ponytail)) are installed at user
scope through each client's own plugin system, never copied into the skills
packages. `scripts/sync-agent-plugins` declares them and installs or updates
each one for Claude Code and Codex, skipping a client that is not on PATH.
Every command it runs is safe to repeat, so the same script bootstraps a new
machine and updates an existing one; `update-system.sh` runs it after the
skills updater.

```bash
~/dotfiles/scripts/sync-agent-plugins
```

To add a plugin, append `<plugin>@<marketplace> <owner/repo>` to the `plugins`
array in the script. After a first install, trust Ponytail's lifecycle hooks
once in Codex with `/hooks`, then start a new thread. Claude Code applies
plugin updates on its next restart.

Ponytail keeps its board data in `~/.config/ponytail/`. Do not Stow that
directory, since folding it into a link would write the data into this repo.
Set a default level with `PONYTAIL_DEFAULT_MODE` in `zsh/.zshrc` if the
default ever needs changing.
