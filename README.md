# Dotfiles

Personal developer environment setup, one folder per platform.

| Folder                 | Platform       | Entry point                                     |
| ---------------------- | -------------- | ----------------------------------------------- |
| [`windows/`](windows/) | Native Windows | [windows/README.md](windows/README.md)          |
| `wsl/` (planned)       | WSL            | the `wsl` branch until it moves into this tree  |
| `macos/` (planned)     | macOS          | the `main` branch until it moves into this tree |

Start with the README of your platform's folder. Repository tooling lives at the
root:

```powershell
pnpm install --frozen-lockfile
pnpm format:check
```

The plan for bringing the remaining platforms in, and for sharing theme tokens
and other common pieces between them, is in [HANDOFF.md](HANDOFF.md).
