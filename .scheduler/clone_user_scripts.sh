#!/bin/bash
set -euo pipefail

SRC_DIR="/boot/config/plugins/user.scripts/scripts"
DST_DIR="$(pwd)/user.scripts/scripts"

echo "Backing up User Scripts"
echo "Source:      $SRC_DIR"
echo "Destination: $DST_DIR"
echo

cd "$DST_DIR"
find . -mindepth 1 -maxdepth 1 -exec rm -rf {} +
cp -r "$SRC_DIR/." .

chmod -R u=rwX,g=rwX,o=rwX "$DST_DIR"

echo
echo "Backup complete."