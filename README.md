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
