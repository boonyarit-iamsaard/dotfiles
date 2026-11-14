# Dotfiles

Personal developer environment setup, one folder per platform.

| Folder                 | Platform       | Entry point                                     |
| ---------------------- | -------------- | ----------------------------------------------- |
| [`windows/`](windows/) | Native Windows | [windows/README.md](windows/README.md)          |
| `macos/` (planned)     | macOS          | the `main` branch until it moves into this tree |
| `wsl/` (planned)       | WSL            | the `wsl` branch until it moves into this tree  |

Start with the README of your platform's folder. Repository tooling lives at the
root:

```sh
pnpm install --frozen-lockfile
pnpm format:check
```

The plan for bringing the remaining platforms in, and for sharing themes and
other common pieces between them, is the spec in
[`.scratch/platform-consolidation/`](.scratch/platform-consolidation/spec.md),
with one ticket per step under its `issues/` folder.
