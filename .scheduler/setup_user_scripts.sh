#!/bin/bash
set -euo pipefail

SRC_DIR="$(pwd)/scripts"
DST_DIR="/boot/config/plugins/user.scripts/scripts"

echo "Installing User Scripts (only adds non-existing)"
echo "Source:      $SRC_DIR"
echo "Destination: $DST_DIR"
echo

for dir in "$SRC_DIR"/*; do
  [ -d "$dir" ] || continue

  name="$(basename "$dir")"
  dest="$DST_DIR/$name"

  if [ -d "$dest" ]; then
    echo "Skipping existing script: $name"
    continue
  fi

  echo "Installing script: $name"
  mkdir -p "$dest"
  cp -a "$dir/." "$dest/"
  chmod +x "$dest/script"
done

chmod -R u=rwX "$DST_DIR"

echo
echo "Installation complete."
echo "Open Settings → User Scripts to verify."