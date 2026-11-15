# Shared files

The non-theme config extraction is tracked in
[issue #10](https://github.com/boonyarit-iamsaard/dotfiles/issues/10).

| File                                                     | Consumers              |
| -------------------------------------------------------- | ---------------------- |
| [`config/lazygit/config.yml`](config/lazygit/config.yml) | macOS, WSL and Windows |
| [`.ideavimrc`](.ideavimrc)                               | macOS, WSL and Windows |

macOS and WSL link these files through relative symlinks in their platform
folders; macOS selects its Default Dark Modern LazyGit variant through
`LG_CONFIG_FILE` in `macos/.zshrc`. Windows links both files through its
manifest and selects the shared Dark 2026 LazyGit variant through
`LG_CONFIG_FILE` in its PowerShell profile. All three platforms have applied and
verified their links. LazyGit's shared base has no theme; each platform selects
a theme variant over it.

Two items from #10 stay per platform:

- **btop settings:** the active theme and preferences differ. macOS uses Default
  Dark Modern, a 1800 ms update interval, and fixed network scaling; WSL uses
  Dark 2026, 2000 ms, and automatic network scaling. Windows has an older config
  with different process sorting and box order. btop also writes its settings on
  exit. Sharing the config would couple these preferences across platforms; its
  theme files are shared separately under [`themes/`](themes/).
- **Global agent instructions:** the only tracked copy is
  [`windows/agents/global-instructions.md`](../windows/agents/global-instructions.md).
  It describes the native Windows dotfiles path, PowerShell 7, and the Windows
  pnpm store policy. macOS and WSL have no tracked equivalent to extract.

Agent skills and theme files have their own guides:
[`skills/README.md`](skills/README.md) and
[`themes/README.md`](themes/README.md).

## Git essentials

[`gitconfig`](gitconfig) declares `core.symlinks=true` once so Git checks out
symlinked `CLAUDE.md` files as links. WSL's managed `~/.gitconfig` includes it,
then loads identity, signing, and machine-only settings from the untracked
`~/.gitconfig.local`. See [WSL setup](../wsl/README.md#git-config) for migration
and Stow commands. Windows links
[`windows/config/git/gitconfig`](../windows/config/git/gitconfig) at
`~\.gitconfig` through its manifest with the same includes, and its verifier
checks that `core.symlinks` comes from the shared file. It is applied and
verified on Windows; `http.sslBackend` stays in Git for Windows' system config.

macOS adoption and verification remain pending in
[issue #11](https://github.com/boonyarit-iamsaard/dotfiles/issues/11).
