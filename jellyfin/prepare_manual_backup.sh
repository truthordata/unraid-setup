#!/usr/bin/env bash
set -euo pipefail

CONTAINER="Jellyfin"
JELLYFIN_DIR="/mnt/user/appdata/Jellyfin"

VERSION="$(docker exec "$CONTAINER" /jellyfin/jellyfin --version 2>&1 || true)"

if [[ "$VERSION" != "Jellyfin.Server"* ]]; then
    echo "ERROR: Could not determine a valid Jellyfin version."
    echo "Got Output: $VERSION"
    exit 1
fi

echo "Prepping Jellyfin backup info..."
printf 'Jellyfin version: %s\n' "$VERSION" > "$JELLYFIN_DIR/manual-backup-metadata.txt"
printf 'Backup timestamp: %s\n' "$(date --iso-8601=seconds)" >> "$JELLYFIN_DIR/manual-backup-metadata.txt"
echo "backup metadata successfully written to $JELLYFIN_DIR/manual-backup-metadata.txt"

echo "Stopping Jellyfin..."
docker stop "$CONTAINER"
echo "Jellyfin container stopped successfully!"
echo "Ready for manual backup procedure; be sure to restart the container afterward."