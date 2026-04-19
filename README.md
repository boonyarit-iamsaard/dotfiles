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
