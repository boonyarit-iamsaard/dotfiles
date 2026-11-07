#!/bin/zsh

# Remove all Docker containers, unused volumes, networks, and builder cache.
source "${0:A:h:h}/scripts/lib/step-runner.zsh"

docker_available() {
    if command -v docker &> /dev/null; then
        return 0
    fi
    log_error "docker command could not be found. Please ensure it is installed."
    return 1
}

docker_daemon_running() {
    if docker info > /dev/null 2>&1; then
        return 0
    fi
    log_error "Docker daemon is not running."
    log_info "Please start Docker (e.g., 'open -a Docker' on Mac or 'sudo systemctl start docker' on Linux) and try again."
    return 1
}

log_info "Starting Docker System Cleanup..."
precondition "Docker on PATH" docker_available
precondition "Docker daemon availability" docker_daemon_running

log_info "Checking for containers to remove..."
CONTAINER_IDS=$(docker ps -aq)
if [[ -z "$CONTAINER_IDS" ]]; then
    step_skip "Removing Docker containers" "No containers found. Skipping removal."
else
    # Docker expects each ID as an argument; zsh does not split scalars implicitly.
    step error "Removing Docker containers" docker rm -f ${=CONTAINER_IDS}
fi
step error "Pruning unused volumes" docker volume prune -af
step error "Pruning unused networks" docker network prune -f

# Builder prune may fail with 404 when BuildKit is disabled or unsupported.
if ! step warn "Pruning builder cache" docker builder prune -af; then
    log_warn "Builder cache prune failed (BuildKit might be disabled or unsupported). Continuing..."
fi

log_info "--- Final Disk Usage ---"
step warn "Docker disk usage" docker system df

steps_finish "Docker cleanup process finished."
exit $?
