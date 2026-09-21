#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

compose() {
    docker compose \
        --project-directory "$PROJECT_DIR" \
        -f "$PROJECT_DIR/docker-compose.yml" \
        "$@"
}

# ----------------- MANUAL BACKUPS -----------------
# Kick off a manual backup dump of paperless (it's not scheduled like the others are) for snapshotting.
bash $PROJECT_DIR/../paperless-ngx/do_backup.sh

# ----------------- LOCAL SNAPSHOTS -----------------
# We do a "manual" snapshot of jellyfin, which requires its own procedure.
bash $PROJECT_DIR/do_jellyfin_backup.sh

# Create snapshots of everything else
compose run --rm resticprofile --name almost_everything backup

# ----------------- REMOTE SNAPSHOTS -----------------
# Copy all local snapshots to the remote location in Backblaze B2
compose run --rm resticprofile --name remote copy

# ----------------- CLEANUP -----------------
# Clean stale Restic cache directories
compose run --rm resticprofile --name local cache --cleanup

# Print out metadata just to keep track of usage, make sure things are aligned.
compose run --rm resticprofile --name local stats --repo /backup_repo --mode raw-data
compose run --rm resticprofile --name remote stats --repo /backup_repo --mode raw-data