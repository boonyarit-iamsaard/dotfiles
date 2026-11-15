# Shared themes

Theme files that two or more platforms link live here once, as
`<tool>/<theme>.<ext>`. Each platform links a whole tool folder or file: macOS
and WSL through relative symlinks in their Stow packages, Windows through its
manifest paths. Each platform keeps its own base config and chooses its own
active theme; there is no shared switch.

WSL uses these shared files. Windows uses the LazyGit variants through
`LG_CONFIG_FILE`, links the Dark 2026 btop theme through its manifest, and
copies the active shared LazyDocker variant into its platform config's marker
block. The remaining Windows and macOS adoption is tracked in
[issue #9](https://github.com/boonyarit-iamsaard/dotfiles/issues/9).

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
  The platforms must pin the same commit.
- **Catppuccin Mocha**: `btop/catppuccin-mocha.theme` and
  `lazygit/catppuccin-mocha.yml` (the yellow accent) are vendored byte for byte
  from the official `catppuccin/<port>` repos at the commits in
  [`catppuccin.json`](catppuccin.json). Catppuccin ships no lazydocker theme, so
  `lazydocker/catppuccin-mocha.yml` is a hand port of the lazygit keys.
  `tmux/catppuccin.conf` configures the `catppuccin/tmux` plugin, and the
  starship file is a hand-written prompt in Catppuccin colours. It is WSL's
  copy; Windows' `starship.catppuccin-mocha.toml` differs and is reconciled when
  Windows links this one.
- **Default Dark Modern**: hand ports of VS Code's
  [`dark_modern.json`](https://github.com/microsoft/vscode/blob/main/extensions/theme-defaults/themes/dark_modern.json)
  and its registered dark defaults, each colour commented with its VS Code key.

`wsl/scripts/test_theme_extras.py` checks the vendored files against their pins
(macOS gets its copy when it links these files). The Catppuccin check downloads
from GitHub and skips when offline.

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
