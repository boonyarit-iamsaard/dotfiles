# Palette owned upstream; theme extras vendored at the lazy-lock pin

The dark 2026 palette lives in `boonyarit-iamsaard/dark-2026.nvim` (`lua/dark-2026/palette.lua`), which also ships per-tool theme extras under `extras/`. This repo vendors those extras as plain stowed files pinned to the plugin commit in `config/nvim/lazy-lock.json`, and a test fails when a vendored extra drifts from that pin. We chose this so there is exactly one palette, stow keeps linking plain files with no dependency on nvim's plugin directory, and lazydocker (single `config.yml`, no includes) is handled the same way as every other tool.

## Considered Options

- **Render the palette in this repo**: rejected; it creates a second palette alongside the one dark-2026.nvim already owns.
- **Point tool configs at `~/.local/share/nvim/lazy/dark-2026.nvim/extras/...`**: rejected; tmux and lazygit would break on machines where nvim hasn't installed the plugin, and lazydocker can't load a second file anyway.

## Consequences

Upstream extras are hand-maintained against `palette.lua` (no generator as of `d9ee531`), so palette/extra agreement inside dark-2026.nvim holds by convention there; this repo's drift test only guarantees vendored copies match the pin.
