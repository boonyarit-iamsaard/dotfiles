#!/bin/zsh

# ==========================================
# System Update Script
# ==========================================
#
# Description:
#   Updates system packages via APT (Ubuntu/Debian), Homebrew, and NPM.
#   Defensively checks for package manager existence before running.
#   Uses Unicode escape codes for robust emoji support.
#
# Usage:
#   ./update-system.sh
#
# ==========================================

# --- Configuration & Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Emoji Definitions (Unicode Escapes) ---
# We use printf to generate emojis so the script file itself remains pure ASCII.
# This prevents encoding issues when copying/pasting.
EMOJI_INFO=$(printf '\U2139\UFE0F')     # Information Source
EMOJI_SUCCESS=$(printf '\U2705')        # White Heavy Check Mark
EMOJI_WARN=$(printf '\U26A0\UFE0F')     # Warning Sign
EMOJI_ERROR=$(printf '\U274C')          # Cross Mark
EMOJI_OUTPUT=$(printf '\U1F539')        # Small Blue Diamond
EMOJI_BAD_OUT=$(printf '\U1F534')       # Red Circle
EMOJI_ROCKET=$(printf '\U1F680')        # Rocket
EMOJI_PARTY=$(printf '\U1F389')         # Party Popper

# --- Helper Functions ---

get_timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

log_info() {
    printf "${BLUE}[%s] ${EMOJI_INFO}  ${NC}%s\n" "$(get_timestamp)" "$1"
}

log_success() {
    printf "${GREEN}[%s] ${EMOJI_SUCCESS}  ${NC}%s\n" "$(get_timestamp)" "$1"
}

log_warn() {
    printf "${YELLOW}[%s] ${EMOJI_WARN}  ${NC}%s\n" "$(get_timestamp)" "$1"
}

log_error() {
    printf "${RED}[%s] ${EMOJI_ERROR}  ${NC}%s\n" "$(get_timestamp)" "$1"
}

# Wraps a command to timestamp its standard output and error
execute_and_log() {
    setopt local_options pipefail

    # Execute command, redirect stderr to stdout, and pipe to formatting loop
    "$@" 2>&1 | while IFS= read -r line; do
        # Handle empty lines
        if [[ -z "${line// /}" ]]; then
             printf "${CYAN}[%s] ${EMOJI_OUTPUT}  ${NC}---\n" "$(get_timestamp)"
             continue
        fi

        # Highlight lines containing "Error" in Red, otherwise Cyan
        if [[ "$line" == *"Error"* || "$line" == *"Err"* ]]; then
             printf "${RED}[%s] ${EMOJI_BAD_OUT}  %s${NC}\n" "$(get_timestamp)" "$line"
        else
             printf "${CYAN}[%s] ${EMOJI_OUTPUT}  ${NC}%s\n" "$(get_timestamp)" "$line"
        fi
    done

    return $pipestatus[1]
}

# --- Main Execution ---

echo -e "${YELLOW}[$(get_timestamp)] ${EMOJI_ROCKET}  Starting System Update Process...${NC}"

# 1. Update APT (Ubuntu/Debian)
# Defensive: Check if 'apt' exists first
if command -v apt &> /dev/null; then
    log_info "Detected 'apt' package manager. Checking sudo permissions..."

    # Refresh sudo credentials upfront so the password prompt isn't hidden by the logger
    if ! sudo -v; then
        log_error "Sudo authentication failed. Skipping APT update."
    else
        log_info "Updating APT repositories..."
        execute_and_log sudo apt update

        log_info "Upgrading APT packages..."
        execute_and_log sudo apt upgrade -y

        log_info "Autoremoving unused packages..."
        execute_and_log sudo apt autoremove -y

        log_info "Cleaning APT cache..."
        execute_and_log sudo apt-get clean

        log_success "APT update sequence completed."
    fi
else
    log_warn "'apt' command not found. Skipping APT update."
fi

# 2. Update Homebrew
# Defensive: Check if 'brew' exists first
if command -v brew &> /dev/null; then
    log_info "Detected 'brew' package manager. Updating..."

    if execute_and_log brew upgrade; then
        log_success "Homebrew packages upgraded."
    else
        log_error "Homebrew upgrade encountered issues."
    fi

    log_info "Cleaning Homebrew..."
    if execute_and_log brew cleanup --prune=all; then
        log_success "Homebrew cleanup finished."
    else
        log_error "Homebrew cleanup encountered issues."
    fi
else
    log_warn "'brew' command not found. Skipping Homebrew update."
fi

# 3. Update npm global packages
# Defensive: Check if 'npm' exists first
if command -v npm &> /dev/null; then
    log_info "Detected 'npm'. Updating global packages..."

    if execute_and_log npm update -g; then
        log_success "npm global packages updated."
    else
        log_error "npm update encountered issues."
    fi

    log_info "Cleaning npm cache logs..."
    NPM_LOG_DIR="$HOME/.npm/_logs"

    if [ -d "$NPM_LOG_DIR" ]; then
        # We don't pipe rm to execute_and_log as it has no output usually
        # and we need wildcard expansion to work in the shell
        rm -rf "$NPM_LOG_DIR"/*
        log_success "Cleared logs in $NPM_LOG_DIR"
    else
        log_warn "npm log directory not found at $NPM_LOG_DIR. Skipping cleanup."
    fi
else
    log_warn "'npm' command not found. Skipping npm update."
fi

echo -e "\n${GREEN}[$(get_timestamp)] ${EMOJI_PARTY}  System update process finished.${NC}"
