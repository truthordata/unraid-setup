#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

compose() {
    docker compose \
        --project-directory "$PROJECT_DIR" \
        -f "$PROJECT_DIR/docker-compose.yml" \
        "$@"
}

# Create local backup snapshots
compose run --rm resticprofile --name everything backup

# Copy local snapshots to Backblaze B2
#compose run --rm resticprofile --name remote copy

# Clean stale Restic cache directories
#compose run --rm resticprofile --name local cache --cleanup

# Print out metadata just to keep track of usage, make sure things are aligned.
#compose run --rm resticprofile --name local stats --repo /backup_repo --mode raw-data
#compose run --rm resticprofile --name remote stats --repo /backup_repo --mode raw-data