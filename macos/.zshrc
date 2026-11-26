# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

plugins=(
  git
  vi-mode
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

alias nv="nvim"
alias lzd='lazydocker'
alias lzg="lazygit"
alias docker-cleanup="~/docker-cleanup.sh"
# This file's directory after resolving the ~/.zshrc link.
alias update-system="${${(%):-%x}:A:h}/update-system/update-system.sh"

# Keep shell lazygit on the same theme as the terminal; variants share a base.
export LG_CONFIG_FILE="$XDG_CONFIG_HOME/lazygit/config.yml,$XDG_CONFIG_HOME/lazygit/themes/dark-2026.yml"

# bind keys for vi mode
bindkey jj vi-cmd-mode

# go setup
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# custom environment variables
. "$HOME/.local/bin/env"

# ~/.local/bin must precede Homebrew so its gh wrapper shadows /opt/homebrew/bin/gh
# (see "Agent gh wrapper" in README.md).
path=("$HOME/.local/bin" ${path:#$HOME/.local/bin})

# dotnet
export PATH="/usr/local/share/dotnet:$PATH"

# java setup
export JAVA_HOME="$(/usr/libexec/java_home -v 21)"
export PATH="$JAVA_HOME/bin:$PATH"

# starship uses the catppuccin mocha prompt; unset STARSHIP_CONFIG for the built-in default.
export STARSHIP_CONFIG="$HOME/.config/starship.catppuccin-mocha.toml"
eval "$(starship init zsh)"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

autoload -U add-zsh-hook

load-nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"
  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version
    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=($HOME/.docker/completions $fpath)
autoload -Uz compinit && compinit
# End of Docker CLI completions

# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi
