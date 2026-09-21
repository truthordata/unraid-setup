#!/usr/bin/env bash

# Jellyfin requires a manual copying of its runtime files, which requires the container to be shut down.
# This backup approach allows us to take full advantage of how restic works.

set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

compose() {
    docker compose \
        --project-directory "$PROJECT_DIR" \
        -f "$PROJECT_DIR/docker-compose.yml" \
        "$@"
}

# this block sets up the container restart; it runs at the end regardless of this script succeeding or erroring.
cleanup() {
    bash $PROJECT_DIR/../jellyfin/resolve_manual_backup.sh
}
trap cleanup EXIT

# shut down the container, then do the backup.
bash $PROJECT_DIR/../jellyfin/prepare_manual_backup.sh

compose run --rm resticprofile --name jellyfin backup
