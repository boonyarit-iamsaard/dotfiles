# Shared themes

Theme files that two or more platforms link live here once, as
`<tool>/<theme>.<ext>`. Each platform links a whole tool folder or file: macOS
and WSL through relative symlinks in their Stow packages, Windows through its
manifest paths. Each platform keeps its own base config and chooses its own
active theme; there is no shared switch. On Windows the active theme is local to
each machine and applied by `windows/scripts/set-theme.ps1` (see
[ADR 0004](../../docs/adr/0004-active-theme-local-per-machine.md)). macOS's
`macos/scripts/set-theme` drives all its tools, Neovim included. WSL's matching
selector is specified in #27; until it lands, WSL still sets its active theme in
tracked configs.

macOS and WSL link the btop, lazydocker, lazygit, Neovim and tmux folders here.
Windows uses the LazyGit variants through `LG_CONFIG_FILE`, links the btop
themes through its manifest, and has `set-theme` write the active shared
LazyDocker variant into the installed config. macOS's shell startup points
`STARSHIP_CONFIG` at the active theme's starship file here. #27 adds the same
Starship selection to WSL; its Dark 2026 hand port will move here from macOS so
both platforms use one file.

| Folder        | Tool                                                    |
| ------------- | ------------------------------------------------------- |
| `btop/`       | btop `color_theme` files                                |
| `lazydocker/` | lazydocker theme variants                               |
| `lazygit/`    | lazygit theme variants, loaded through `LG_CONFIG_FILE` |
| `nvim/`       | Neovim `themes.<name>` imports (lazygit inside Neovim)  |
| `starship/`   | starship configs, picked through `STARSHIP_CONFIG`      |
| `tmux/`       | tmux theme variants, sourced by `@theme`                |
| `vscode/`     | the VS Code theme Dark 2026 started from                |

Tools only one platform uses keep their theme files in that platform's folder:
Ghostty and superfile on macOS, Windows Terminal and Oh My Posh on Windows.

## Where each file comes from

- **Dark 2026**: theme extras vendored byte for byte from
  [dark-2026.nvim](https://github.com/boonyarit-iamsaard/dark-2026.nvim) at the
  plugin commit in each platform's `lazy-lock.json` (see
  [ADR 0001](../../docs/adr/0001-palette-owned-upstream-extras-vendored.md)).
  The platforms must pin the same commit. dark-2026.nvim ships no starship
  extra, so the existing `macos/.config/starship.dark-2026.toml` is a hand port
  of its palette, each colour commented with its VS Code key. When #27 is
  implemented, move that file to `starship/dark-2026.toml` so macOS and WSL can
  link the same hand port.
- **Catppuccin Mocha and Macchiato**: `btop/catppuccin-<flavour>.theme` and
  `lazygit/catppuccin-<flavour>.yml` (the default mauve accent) are vendored
  byte for byte from the official `catppuccin/<port>` repos at the commits in
  [`catppuccin.json`](catppuccin.json). Catppuccin ships no lazydocker theme, so
  `lazydocker/catppuccin-<flavour>.yml` is a hand port of the lazygit keys.
  `tmux/catppuccin.conf` (Mocha) and `tmux/catppuccin-macchiato.conf` configure
  the `catppuccin/tmux` plugin, and the starship files are hand-written prompts
  in Catppuccin colours.
- **Default Dark Modern**: hand ports of VS Code's
  [`dark_modern.json`](https://github.com/microsoft/vscode/blob/main/extensions/theme-defaults/themes/dark_modern.json)
  and its registered dark defaults, each colour commented with its VS Code key.

`macos/scripts/test_theme_extras.py` and `wsl/scripts/test_theme_extras.py`
check the vendored files against their pins. The Catppuccin check downloads from
GitHub and skips when offline. macOS's superfile Catppuccin themes are not
shared: they live in `macos/.config/superfile/theme/`, pinned to superfile's own
repo in `macos/.config/superfile/upstream.json`, and the macOS test checks them
the same way.

## Refresh a vendored file

A refresh changes every platform, so verify it on each.

- **Dark 2026**: bump the plugin, then copy each extra from the new pin:
  `git -C <dark-2026.nvim checkout> show <commit>:extras/<tool>/<file>`.
- **Catppuccin**: set the port's `commit` in `catppuccin.json`, then download
  each listed file from
  `https://raw.githubusercontent.com/catppuccin/<port>/<commit>/<path>`.

Keep the upstream bytes: `.gitattributes` exempts the vendored Catppuccin files
from whitespace checks, and `.prettierignore` exempts the lazygit one, whose
upstream quoting Prettier would rewrite.
