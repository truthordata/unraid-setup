#!/usr/bin/env bash
set -euo pipefail

APP_CONFIG_FOLDER="/mnt/user/appconfig"

read -r -p "Enter desired destination directory (blank defaults to: ${APP_CONFIG_FOLDER}): " DEST
DEST="${DEST:-$APP_CONFIG_FOLDER}"

mkdir -p "$DEST"

# skips existing dirs
for dir in */; do
  target="$DEST/$dir"
  if [[ -d "$target" ]]; then
    echo "Skipping existing directory: $dir"
    continue
  fi
  cp -a "$dir" "$DEST/"
done

echo "Done."



echo "Copied app config folders to ${DEST}; use this location now for app configuration!"
