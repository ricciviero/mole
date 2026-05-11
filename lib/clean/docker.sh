#!/bin/bash
# Docker Cleanup Module.
# Reclaims space from stopped containers, unused images, build cache.
# Never touches volumes — those hold persistent data (databases).
set -euo pipefail

# Run a single docker prune subcommand (respects DRY_RUN).
# Args:
#   $1 = description shown to the user
#   $2+ = docker subcommand arguments (passed to `docker`)
run_docker_prune() {
    local description="$1"
    shift

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  ${YELLOW}${ICON_DRY_RUN}${NC} $description · would run: docker $*"
        note_activity
        return 0
    fi

    local command_succeeded=false
    if [[ -t 1 ]]; then
        start_section_spinner "Pruning $description..."
    fi
    if docker "$@" > /dev/null 2>&1; then
        command_succeeded=true
    fi
    if [[ -t 1 ]]; then
        stop_section_spinner
    fi

    if [[ "$command_succeeded" == "true" ]]; then
        echo -e "  ${GREEN}${ICON_SUCCESS}${NC} $description"
        note_activity
    else
        echo -e "  ${GRAY}${ICON_WARNING}${NC} $description · skipped (command failed)"
        debug_log "docker $* failed"
    fi
    return 0
}

# Docker prune entrypoint.
# Skips volumes intentionally — database data lives there.
clean_docker_resources() {
    if ! command -v docker > /dev/null 2>&1; then
        debug_log "docker not installed, skipping"
        return 0
    fi

    # Daemon reachable? `docker info` is the canonical liveness probe.
    if ! docker info > /dev/null 2>&1; then
        echo -e "  ${GRAY}${ICON_WARNING}${NC} Docker daemon not running · skipped"
        note_activity
        return 0
    fi

    # System prune covers stopped containers, unused networks, dangling images,
    # and build cache. Volumes are excluded by default — exactly what we want.
    run_docker_prune "Docker system (containers, networks, dangling images, build cache)" \
        system prune -f

    # `image prune -a` also removes images not referenced by any container,
    # including pulled-but-unused tags. Big space win on dev machines.
    run_docker_prune "Docker images (unused, including tagged)" \
        image prune -a -f

    # Build cache layers accumulate independently of system prune in some
    # buildkit setups; flush them too.
    run_docker_prune "Docker buildx cache" \
        builder prune -a -f
}
