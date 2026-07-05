# Dotfiles

Personal shell and tooling configuration managed with GNU Stow.

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

## Claude Code skills (stow)

The `claude` package must be stowed with `--no-folding` so that
`~/.claude/skills` stays a real directory with each skill symlinked
individually:

```bash
cd ~/dotfiles && stow -R --no-folding claude
```

Without `--no-folding`, stow collapses `~/.claude/skills` into a single
symlink. Tools that install skills in place (e.g. `npx impeccable`, which
writes to `~/.claude/skills/impeccable`) then replace that one symlink with a
real directory and take *every* skill offline at once. `--no-folding` limits
the blast radius to the single skill being written.

`impeccable` is **not** version-controlled (see `.gitignore`). It is installed
and updated in place by its own tool, which rewrites its files on every update:

```bash
npx impeccable update   # manages ~/.claude/skills/impeccable and ~/.agents/skills/impeccable in place
```

It is freely re-installable, so it lives as plain files alongside the stowed
skills rather than as tracked symlinks. The custom skills in this repo stay
tracked and symlinked; an impeccable update can only ever touch its own folder.

### When to re-stow

`npx impeccable update` does **not** require a re-stow — it only rewrites its
own folder. Re-stow with `stow -R --no-folding claude` only when:

- You add (or rename) a custom skill under `claude/.claude/skills/` and need it
  symlinked into `~/.claude/skills`.
- An installer ever clobbers `~/.claude/skills` itself (the `--no-folding`
  real-directory layout means a single re-stow restores every link).
