# Dotfiles

Personal shell and tooling configuration managed with GNU Stow.

## Shared config

`config/lazygit/config.yml` and `ideavimrc/.ideavimrc` are relative symlinks to
`shared/config/lazygit/config.yml` and `shared/.ideavimrc`. LazyGit's base has
no theme; `LG_CONFIG_FILE` in `zsh/.zshrc` layers the active theme over it.
btop's settings stay here because each platform keeps its own theme and
preferences. See [shared/README.md](../shared/README.md) for the extraction
status.

Restow these packages from `wsl/`:

```bash
stow --restow --target="$HOME/.config" config
stow --restow --target="$HOME" ideavimrc
```

## Maintenance scripts

`update-system.sh` and `docker-cleanup.sh` share `scripts/lib/step-runner.zsh`:
each prints a step summary and exits 1 when any error-severity step failed
(warnings don't affect the exit status).

## Themes

Three themes are maintained: default dark modern, catppuccin mocha and
dark 2026. Dark 2026 is active in Neovim, tmux, lazygit, lazydocker and btop;
starship runs its built-in default. Each tool has a base config plus one theme
variant per theme in [`../shared/themes/`](../shared/themes/), which every
platform shares. The theme folders and starship files here are relative symlinks
into it (`config/lazygit/themes -> ../../../shared/themes/lazygit`). Switching
is a one-line edit per tool:

| Tool       | Switch                                                                                                                                                            |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| tmux       | `set -g @theme …` in `tmux/.tmux.conf` (variants in `shared/themes/tmux/`); restart the server for a clean switch                                                 |
| lazygit    | second path of `LG_CONFIG_FILE` in `zsh/.zshrc` (variants in `shared/themes/lazygit/`)                                                                            |
| lazydocker | replace the block between the `# >>> theme` markers in `config/lazydocker/config.yml` with the body of `shared/themes/lazydocker/<name>.yml`                      |
| Neovim     | `colorscheme` in `config/nvim/lua/plugins/colorscheme.lua`; keep exactly one `{ import = "themes.<name>" }` line uncommented for dark 2026 or default dark modern |
| starship   | `STARSHIP_CONFIG` in `zsh/.zshrc` (`config/starship.<name>.toml`; catppuccin mocha and default dark modern only); unset for the built-in default                  |
| btop       | `color_theme` in `config/btop/btop.conf` (variants in `shared/themes/btop/`)                                                                                      |

Where each theme file comes from, its pin, and how to refresh it are in
[shared/themes/README.md](../shared/themes/README.md). The dark 2026 extras are
pinned to the plugin commit in `config/nvim/lazy-lock.json` (see
[ADR 0001](../docs/adr/0001-palette-owned-upstream-extras-vendored.md)), the
Catppuccin files to `shared/themes/catppuccin.json`;
`python3 -m unittest scripts/test_theme_extras.py` fails on any drift and when a
theme path here stops linking into `shared/themes/`.

## Go toolchain

Go is installed with Homebrew and pinned so routine `brew upgrade` runs do not
change the local Go version unexpectedly.

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
tool itself is kept current by `update-system.sh`, which also flushes SDKMAN
caches.

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

Skills come from one manifest, `shared/skills/skills.json` (see
[shared/skills/README.md](../shared/skills/README.md) and
[ADR 0002](../docs/adr/0002-skills-shared-from-one-manifest.md)):

- Upstream skills from the owner's fork of Matt Pocock's skills, in a read-only
  checkout at `~/workspace/personal/skills`.
- Personal skills (`commit-message`, `edit-prose`, `runbook`,
  `typescript-house-style`), kept once under `shared/skills/`.
- Vendored skills (`impeccable`, `ponytail`), kept under `shared/skills/vendor/`
  at the pins the manifest records.

The `agents` and `claude` Stow packages hold only flattened, relative symlinks:
into the checkout for upstream skills and into `shared/skills/` for the rest.
Claude Code, Codex, and other Agent Skills clients therefore see the same
versions.

Update the checkout and reconcile both consumers with:

```bash
~/dotfiles/wsl/scripts/update-skills
```

Use `--dry-run` to preview changes, `--check` in diagnostics, and `--migrate`
only for the initial conversion from copied skills. The updater requires Python
3 and uses only its standard library. It refuses to pull when the skills
checkout has local changes. Routine reconciliation refuses to replace any real
directory or unmanaged symlink, and rejects any real skill directory in a
package: declare the skill in the manifest instead. The one-time `--migrate`
mode is deliberately broader: it matches each Claude `SKILL.md` to its grouped
Agents counterpart, snapshots both complete consumer trees, and then archives
the verified copies.

The engineering and productivity source catalogs remain separate and are linked
into each consumer as `ENGINEERING.md` and `PRODUCTIVITY.md`.

### Stow layout

The user-level skill directories `~/.agents/skills` and `~/.claude/skills` stay
real. The updater creates them before the final Stow operation, so Stow cannot
collapse either one into a single symlink, and lets Stow fold only the
individual skill directories. The updater re-stows both consumers itself,
including after a failed run that had already unlinked them.

Impeccable's Claude Code subagents are tracked symlinks in
`claude/.claude/agents/` that point into `shared/skills/vendor/impeccable/`.
Never run `npx impeccable update` in the home directory: refresh the vendored
payload as `shared/skills/README.md` describes.

### Agent plugins

Claude Code plugins are pinned under `plugins.claude` in the manifest. Ponytail
is the only one, installed for its session hook and slash commands.
`scripts/sync-agent-plugins` pins each plugin's marketplace to its ref,
re-adding the marketplace when the pin changes. It then installs and updates the
plugin at user scope, and skips Claude Code when it is not on PATH. Every
command it runs is safe to repeat, so the same script bootstraps a new machine
and updates an existing one; `update-system.sh` runs it after the skills
updater. Claude Code applies plugin updates on its next restart.

```bash
~/dotfiles/wsl/scripts/sync-agent-plugins
```

Codex gets Ponytail's skills from the vendored copy in `~/.agents/skills`, not
from a plugin. A machine that installed the Codex plugin earlier sees each
Ponytail skill twice until it runs `codex plugin remove ponytail@ponytail`.

Ponytail keeps its board data in `~/.config/ponytail/`. Do not Stow that
directory, since folding it into a link would write the data into this repo. Set
a default level with `PONYTAIL_DEFAULT_MODE` in `zsh/.zshrc` if the default ever
needs changing.
