#!/usr/bin/env bash
set -euo pipefail

APP_CONFIG_FOLDER="/mnt/user/appconfig"

read -r -p "Enter your desired config folder (blank defaults to: ${APP_CONFIG_FOLDER}): " DEST
DEST="${DEST:-$APP_CONFIG_FOLDER}"

if [[ ! -d "$DEST" ]]; then
  echo "Error: destination folder does not exist: $DEST. \nIdeally it should be an unraid share \
  directory with its storage set to your primary drive." >&2
  exit 1
fi

# skips existing dirs
for dir in */; do
  target="$DEST/$dir"
  if [[ -d "$target" ]]; then
    echo "Skipping existing directory: $dir"
    continue
  fi
  cp -a "$dir" "$DEST/"
done

echo "Initial setup complete: copied app config folders to ${DEST}. \
\nUse this location now for app configuration!"
