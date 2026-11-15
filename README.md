# Dotfiles

Personal developer environment setup, one folder per platform.

| Folder                 | Platform       | Entry point                            |
| ---------------------- | -------------- | -------------------------------------- |
| [`windows/`](windows/) | Native Windows | [windows/README.md](windows/README.md) |
| [`macos/`](macos/)     | macOS          | [macos/README.md](macos/README.md)     |
| [`wsl/`](wsl/)         | WSL            | [wsl/README.md](wsl/README.md)         |

Start with the README of your platform's folder. Each machine links its setup
from its own folder in this one checkout.

Shared non-theme config and the items kept per platform are described in
[`shared/README.md`](shared/README.md).

Agent skills are kept once in [`shared/skills/`](shared/skills/) and listed in
one manifest, `shared/skills/skills.json`. WSL and Windows read it; macOS
adoption remains in
[#16](https://github.com/boonyarit-iamsaard/dotfiles/issues/16) (see
[shared/skills/README.md](shared/skills/README.md)).

Theme files that more than one platform links are kept once in
[`shared/themes/`](shared/themes/) (see
[shared/themes/README.md](shared/themes/README.md)).

Repository tooling lives at the root:

```sh
pnpm install --frozen-lockfile
pnpm format:check
```

The plan for finishing the move, and for sharing themes and other common pieces
between the platforms, is the spec in
[issue #14](https://github.com/boonyarit-iamsaard/dotfiles/issues/14), with one
sub-issue per step.
