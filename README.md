# Dotfiles

Personal developer environment setup, one folder per platform.

| Folder                 | Platform       | Entry point                            |
| ---------------------- | -------------- | -------------------------------------- |
| [`windows/`](windows/) | Native Windows | [windows/README.md](windows/README.md) |
| [`macos/`](macos/)     | macOS          | [macos/README.md](macos/README.md)     |
| [`wsl/`](wsl/)         | WSL            | [wsl/README.md](wsl/README.md)         |

Start with the README of your platform's folder. Each machine links its setup
from its own folder in this one checkout.

Repository tooling lives at the root:

```sh
pnpm install --frozen-lockfile
pnpm format:check
```

The plan for finishing the move, and for sharing themes and other common pieces
between the platforms, is the spec in
[issue #14](https://github.com/boonyarit-iamsaard/dotfiles/issues/14), with one
sub-issue per step.
