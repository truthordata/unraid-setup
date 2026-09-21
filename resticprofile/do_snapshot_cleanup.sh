#!/usr/bin/env bash

# ------- REMINDER: This should be done sparingly, as it is a heavy operation ---------
# Recommended only weekly or monthly.
# It removes all old snapshots and related blobs, keeping only those that obey their defined retention policies.

set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

compose() {
    docker compose \
        --project-directory "$PROJECT_DIR" \
        -f "$PROJECT_DIR/docker-compose.yml" \
        "$@"
}

# Apply retention and prune the local repository
compose run --rm resticprofile --name local forget --prune

# Apply the same retention policy and prune the B2 repository
compose run --rm resticprofile --name remote forget --prune