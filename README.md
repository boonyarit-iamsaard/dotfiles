# Dotfiles

Personal developer environment setup, one folder per platform.

| Folder                 | Platform       | Entry point                            |
| ---------------------- | -------------- | -------------------------------------- |
| [`windows/`](windows/) | Native Windows | [windows/README.md](windows/README.md) |
| [`macos/`](macos/)     | macOS          | [macos/README.md](macos/README.md)     |
| [`wsl/`](wsl/)         | WSL            | [wsl/README.md](wsl/README.md)         |

Start with the README of your platform's folder. The WSL files are in `wsl/`,
but the WSL machine still runs from the `wsl` branch until its setup is pointed
at this folder.

Repository tooling lives at the root:

```sh
pnpm install --frozen-lockfile
pnpm format:check
```

The plan for finishing the move, and for sharing themes and other common pieces
between the platforms, is the spec in
[`.scratch/platform-consolidation/`](.scratch/platform-consolidation/spec.md),
with one ticket per step under its `issues/` folder.
