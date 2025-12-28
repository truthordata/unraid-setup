#!/usr/bin/env bash
set -euo pipefail

DUMP_DIR="/db_dumps"


echo "Preparing to do restoration..."
echo "Searching for Immich database dumps..."

# Get sorted list (newest first)
DUMPS=$(ls -1t "$DUMP_DIR" 2>/dev/null || true)

if [ -z "$DUMPS" ]; then
  echo "ERROR: No dumps found in $DUMP_DIR"
  exit 1
fi

echo
echo "Available dumps (newest first):"
echo

i=1
for f in $DUMPS; do
  if [ "$i" -eq 1 ]; then
    printf "  [%d] %s  (latest)\n" "$i" "$f"
  else
    printf "  [%d] %s\n" "$i" "$f"
  fi
  i=$((i + 1))
done

echo
printf "Select dump to restore [default: 1]: "
read choice
[ -z "$choice" ] && choice=1

case "$choice" in
  *[!0-9]*)
    echo "Invalid selection."
    exit 1
    ;;
esac

i=1
DUMP=""
for f in $DUMPS; do
  if [ "$i" -eq "$choice" ]; then
    DUMP="$DUMP_DIR/$f"
    break
  fi
  i=$((i + 1))
done

if [ -z "$DUMP" ]; then
  echo "Invalid selection."
  exit 1
fi

echo
echo "Selected dump:"
echo "  $DUMP"
echo


echo "Pre-restore sanity check: inspecting dump contents..."
TOC="$(pg_restore -l "$DUMP")" || {
  echo "ERROR: Dumped archive was unreadable; stopping..."
  exit 1
}

# Simple check: Fail if no entries at all
TOC_ENTRIES=$(pg_restore -l "$DUMP" \
  | awk -F: '/TOC Entries/ { gsub(/^[[:space:]]+/, "", $2); print $2 }')
if [ -z "$TOC_ENTRIES" ] || [ "$TOC_ENTRIES" -eq 0 ]; then
  echo
  echo "ERROR: Dump contains no TOC entries. Aborting."
  exit 1
fi

echo
echo "Dump appears to contain data: here is a preview: "
echo

# Print a small sample so the operator can eyeball it
pg_restore -l "${DUMP}" | grep -E "TABLE DATA" | head -n 10

echo
read -r -p "Proceed with DESTRUCTIVE restore of database '${DB_NAME}'? [y/N]: " CONFIRM

case "${CONFIRM}" in
  y|Y|yes|YES)
    ;;
  *)
    echo "Restore aborted by user."
    exit 0
    ;;
esac

echo
echo "Restoring database '${DB_NAME}'..."

pg_restore \
  --clean \
  --if-exists \
  --host=database \
  --port=5432 \
  --username="${DB_USERNAME}" \
  --dbname="${DB_NAME}" \
  "${DUMP}"

echo
echo "Restore completed."
