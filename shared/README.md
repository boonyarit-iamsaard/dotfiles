# Shared files

The non-theme config extraction is tracked in
[issue #10](https://github.com/boonyarit-iamsaard/dotfiles/issues/10).

| File                                                     | Consumers                                |
| -------------------------------------------------------- | ---------------------------------------- |
| [`config/lazygit/config.yml`](config/lazygit/config.yml) | WSL; macOS and Windows relinking pending |
| [`.ideavimrc`](.ideavimrc)                               | WSL; macOS and Windows relinking pending |

WSL links these files through relative symlinks in its Stow packages. macOS and
Windows still use their platform copies until each platform completes its relink
and verification. LazyGit's shared base has no theme; each platform selects a
theme variant through `LG_CONFIG_FILE` when it adopts the base.

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
