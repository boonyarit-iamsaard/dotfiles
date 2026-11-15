# Read by every zsh, interactive or not, so agents' tool shells see it too.
# ~/.local/bin must precede Homebrew so its gh wrapper shadows /opt/homebrew/bin/gh
# (see "Agent gh wrapper" in README.md).
path=("$HOME/.local/bin" ${path:#$HOME/.local/bin})

# lazygit, lazydocker and superfile read their config from ~/.config, as on
# WSL, instead of ~/Library/Application Support.
export XDG_CONFIG_HOME="$HOME/.config"
