# Read by every zsh, interactive or not, so agents' tool shells see it too.
# ~/.local/bin must precede Homebrew so its gh wrapper shadows /opt/homebrew/bin/gh
# (see "Agent gh wrapper" in README.md).
path=("$HOME/.local/bin" ${path:#$HOME/.local/bin})
