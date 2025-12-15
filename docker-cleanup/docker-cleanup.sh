#!/bin/zsh
 
# ==========================================
# Docker System Cleanup Script
# ==========================================
#
# Description:
#   Safely removes all Docker containers, volumes, networks, and builder cache.
#   Includes checks for Docker daemon availability and handles empty states.
#   Uses Unicode escape codes for robust emoji support.
#
# Usage:
#   ./docker-cleanup.sh
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

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 command could not be found. Please ensure it is installed."
        exit 1
    fi
}

# Wraps a command to timestamp its standard output and error
execute_and_log() {
    # setopt pipefail ensures the function returns the exit code of the command,
    # not the exit code of the logging loop.
    setopt local_options pipefail

    # Execute command, redirect stderr to stdout, and pipe to formatting loop
    "$@" 2>&1 | while IFS= read -r line; do
        # Handle empty lines (or lines with only spaces) by printing a visual separator
        if [[ -z "${line// /}" ]]; then
             printf "${CYAN}[%s] ${EMOJI_OUTPUT}  ${NC}---\n" "$(get_timestamp)"
             continue
        fi

        # Highlight lines containing "Error" in Red, otherwise Cyan
        if [[ "$line" == *"Error"* ]]; then
             printf "${RED}[%s] ${EMOJI_BAD_OUT}  %s${NC}\n" "$(get_timestamp)" "$line"
        else
             printf "${CYAN}[%s] ${EMOJI_OUTPUT}  ${NC}%s\n" "$(get_timestamp)" "$line"
        fi
    done

    # Return the exit code of the actual command (first item in zsh pipestatus array)
    return $pipestatus[1]
}

# --- Main Execution ---

echo -e "${YELLOW}[$(get_timestamp)] ${EMOJI_ROCKET}  Starting Docker System Cleanup...${NC}"

# 1. Defensive Check: Is Docker installed?
check_command "docker"

# 2. Defensive Check: Is Docker Daemon running?
if ! docker info > /dev/null 2>&1; then
    log_error "Docker daemon is not running."
    log_info "Please start Docker (e.g., 'open -a Docker' on Mac or 'sudo systemctl start docker' on Linux) and try again."
    exit 1
fi

# 3. Remove all containers
log_info "Checking for containers to remove..."
CONTAINER_IDS=$(docker ps -aq)

if [ -z "$CONTAINER_IDS" ]; then
    log_warn "No containers found. Skipping removal."
else
    # We pipe the removal command to our logger
    # ZSH FIX: Use ${=VAR} to force word splitting, otherwise it's passed as one string
    if execute_and_log docker rm -f ${=CONTAINER_IDS}; then
        log_success "All containers removed."
    else
        log_error "Failed to remove some containers."
    fi
fi

# 4. Prune Volumes
log_info "Pruning unused volumes..."
if execute_and_log docker volume prune -af; then
    log_success "Volumes pruned."
else
    log_error "Failed to prune volumes."
fi

# 5. Prune Networks
log_info "Pruning unused networks..."
if execute_and_log docker network prune -f; then
    log_success "Networks pruned."
else
    log_error "Failed to prune networks."
fi

# 6. Prune Builder Cache
log_info "Pruning builder cache..."
# Builder prune often fails with 404 on daemons where BuildKit is disabled or unsupported.
# We treat this as a warning instead of a critical failure.
if execute_and_log docker builder prune -af; then
    log_success "Builder cache pruned."
else
    log_warn "Builder cache prune failed (BuildKit might be disabled or unsupported). Continuing..."
fi

# 7. Final Status
echo -e "\n${YELLOW}--- Final Disk Usage ---${NC}"
# We log this too so the table rows get timestamps
execute_and_log docker system df

echo -e "\n${GREEN}[$(get_timestamp)] ${EMOJI_PARTY}  Docker cleanup process finished.${NC}"
