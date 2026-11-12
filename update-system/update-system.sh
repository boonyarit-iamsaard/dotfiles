#!/bin/zsh

# Update system and development tooling, leaving pinned tool versions unchanged.
source "${0:A:h:h}/scripts/lib/step-runner.zsh"

is_wsl() {
    [[ -r /proc/sys/kernel/osrelease ]] && grep -qi microsoft /proc/sys/kernel/osrelease
}

log_info "Starting System Update Process..."

if command -v apt &> /dev/null; then
    log_info "Detected 'apt' package manager. Checking sudo permissions..."
    group_begin "APT maintenance"
    # Refresh sudo credentials upfront so the password prompt isn't hidden by the logger
    if ! precondition "Sudo authentication" sudo -v; then
        log_error "Sudo authentication failed. Skipping APT update."
    fi
    step error "Updating APT repositories" sudo apt update
    step error "Upgrading APT packages" sudo apt upgrade -y
    step error "Autoremoving unused packages and old configs" sudo apt autoremove --purge -y
    step error "Cleaning APT cache" sudo apt-get clean
    if command -v journalctl &> /dev/null; then
        step warn "Vacuuming systemd journal logs older than 14 days" sudo journalctl --vacuum-time=14d
    else
        step_skip "Vacuuming systemd journal logs" "'journalctl' command not found. Skipping systemd journal cleanup."
    fi
    group_end

    if [[ -f /var/run/reboot-required ]]; then
        if is_wsl; then
            log_warn "WSL restart required for some updates to fully apply. From Windows, run: wsl --shutdown"
        else
            log_warn "System reboot required for some updates to fully apply."
        fi
    fi
else
    step_skip "APT maintenance" "'apt' command not found. Skipping APT update."
fi

# Pinned Homebrew formulas (including Go) are upgraded explicitly when needed.
if command -v brew &> /dev/null; then
    log_info "Detected 'brew' package manager. Updating..."
    log_info "Pinned Homebrew formulas such as Go are skipped by routine upgrades."
    step error "Upgrading Homebrew packages" brew upgrade
    step error "Cleaning Homebrew" brew cleanup --prune=all
else
    step_skip "Homebrew update" "'brew' command not found. Skipping Homebrew update."
fi

if command -v npm &> /dev/null; then
    log_info "Detected 'npm'. Updating global packages..."
    step error "Updating npm global packages" npm update -g
    NPM_LOG_DIR="$HOME/.npm/_logs"
    if [[ -d "$NPM_LOG_DIR" ]]; then
        step error "Cleaning npm cache logs" rm -rf -- "$NPM_LOG_DIR"/*(N)
    else
        step_skip "Cleaning npm cache logs" "npm log directory not found at $NPM_LOG_DIR. Skipping cleanup."
    fi
else
    step_skip "npm update" "'npm' command not found. Skipping npm update."
fi

# Composer itself is updated only when the installation supports self-update.
if command -v composer &> /dev/null; then
    log_info "Detected 'composer'. Checking for self-update support..."
    if composer self-update --help &> /dev/null; then
        step error "Updating Composer" composer self-update --stable --no-interaction
    else
        log_info "Composer self-update is unavailable. The system package manager may manage this installation."
    fi

    COMPOSER_GLOBAL_HOME="${COMPOSER_HOME:-$HOME/.config/composer}"
    if [[ -z "$COMPOSER_HOME" && ! -f "$COMPOSER_GLOBAL_HOME/composer.json" && -f "$HOME/.composer/composer.json" ]]; then
        COMPOSER_GLOBAL_HOME="$HOME/.composer"
    fi
    if [[ -f "$COMPOSER_GLOBAL_HOME/composer.json" ]]; then
        COMPOSER_HOME="$COMPOSER_GLOBAL_HOME" step error "Updating global Composer packages" composer global update --no-interaction
    else
        log_info "No global Composer packages are configured. Skipping their update."
    fi
else
    step_skip "Composer update" "'composer' command not found. Skipping Composer update."
fi

# This script does not source .zshrc; SDKMAN supplies sdk through its init script.
# Candidate versions (JDK, Maven) stay pinned and are upgraded manually.
SDKMAN_INIT="${SDKMAN_DIR:-$HOME/.sdkman}/bin/sdkman-init.sh"
if [[ -s "$SDKMAN_INIT" ]]; then
    log_info "Detected SDKMAN. Updating the tool and flushing caches..."
    source "$SDKMAN_INIT"
    step warn "Updating SDKMAN" sdk selfupdate
    step warn "Flushing SDKMAN temp, archive, and metadata caches" sdk flush
else
    step_skip "SDKMAN update" "SDKMAN not found. Skipping SDKMAN update."
fi

# A separately installed updater may override the default beside the resolved script.
SKILLS_UPDATER="${SKILLS_UPDATER:-${0:A:h:h}/scripts/update-skills}"
if [[ -x "$SKILLS_UPDATER" ]]; then
    step warn "Updating shared agent skills" "$SKILLS_UPDATER"
else
    step_skip "Updating shared agent skills" "Skills updater not found at $SKILLS_UPDATER. Skipping."
fi

PLUGINS_SYNC="${PLUGINS_SYNC:-${0:A:h:h}/scripts/sync-agent-plugins}"
if [[ -x "$PLUGINS_SYNC" ]]; then
    step warn "Updating agent plugins" "$PLUGINS_SYNC"
else
    step_skip "Updating agent plugins" "Plugin sync not found at $PLUGINS_SYNC. Skipping."
fi

steps_finish "System update process finished."
exit $?
