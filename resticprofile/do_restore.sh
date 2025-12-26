#!/usr/bin/env bash
set -euo pipefail

########################################
# Load environment
########################################

source ./.env

########################################
# Fetch snapshots (newest → oldest)
########################################

mapfile -t SNAPSHOTS < <(
  docker compose run --rm resticprofile snapshots \
    | awk 'NR>2 { print $1 "|" $2 " " $3 }' \
    | tac
)

if [[ ${#SNAPSHOTS[@]} -eq 0 ]]; then
  echo "No snapshots found"
  exit 1
fi

########################################
# Display menu
########################################

echo
echo "Available snapshots:"
echo

i=1
for entry in "${SNAPSHOTS[@]}"; do
  SNAP_ID="${entry%%|*}"
  SNAP_DATE="${entry##*|}"
  printf "  [%d] %s  (%s)\n" "$i" "$SNAP_ID" "$SNAP_DATE"
  ((i++))
done

echo
read -rp "Select snapshot [1]: " SELECTION
SELECTION="${SELECTION:-1}"

if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || (( SELECTION < 1 || SELECTION > ${#SNAPSHOTS[@]} )); then
  echo "Invalid selection"
  exit 1
fi

########################################
# Resolve snapshot
########################################

INDEX=$((SELECTION - 1))
SELECTED="${SNAPSHOTS[$INDEX]}"
SNAPSHOT_ID="${SELECTED%%|*}"

echo
echo "Selected snapshot: $SNAPSHOT_ID"
echo "Restore target:    $RESTORE_FOLDER"
echo

########################################
# Confirm
########################################

read -rp "Proceed with restore? [y/N]: " CONFIRM
case "$CONFIRM" in
  y|Y) ;;
  *) echo "Aborted."; exit 0 ;;
esac

########################################
# Restore
########################################

docker compose run --rm resticprofile restore \
  --snapshot "$SNAPSHOT_ID" \
  --target /restore
