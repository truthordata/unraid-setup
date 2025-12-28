#!/usr/bin/env bash
set -euo pipefail

DUMP_DIR="/db_dumps"
PATTERN="immich-*.dump"

echo "Searching for Immich database dumps..."
mapfile -t DUMPS < <(ls -1t "${DUMP_DIR}/${PATTERN}" 2>/dev/null || true)

if [ "${#DUMPS[@]}" -eq 0 ]; then
  echo "ERROR: No dumps found in ${DUMP_DIR}"
  exit 1
fi

echo
echo "Available dumps (newest first):"
echo

PS3=$'\nSelect dump to restore [default: 1]: '

select DUMP in "${DUMPS[@]}"; do
  if [ -z "${REPLY}" ]; then
    DUMP="${DUMPS[0]}"
    break
  fi

  if [ -n "${DUMP}" ]; then
    break
  fi

  echo "Invalid selection."
done

echo
echo "Selected dump:"
echo "  ${DUMP}"
echo

echo "Pre-restore sanity check: inspecting dump contents by giving a data preview..."
echo

# Print a small sample so the operator can eyeball it
pg_restore -l "${DUMP}" | grep -E "TABLE DATA" | head -n 10

# Hard failure if no data entries exist
if ! pg_restore -l "${DUMP}" | grep -q "TABLE DATA"; then
  echo
  echo "ERROR: Dump contains no TABLE DATA entries. Aborting."
  exit 1
fi

echo
echo "Dump appears to contain data."

echo
read -r -p "Proceed with DESTRUCTIVE restore of database '${DB_DATABASE_NAME}'? [y/N]: " CONFIRM

case "${CONFIRM}" in
  y|Y|yes|YES)
    ;;
  *)
    echo "Restore aborted by user."
    exit 0
    ;;
esac

echo
echo "Restoring database '${DB_DATABASE_NAME}'..."

pg_restore \
  --clean \
  --if-exists \
  --host=database \
  --port=5432 \
  --username="${DB_USERNAME}" \
  --dbname="${DB_DATABASE_NAME}" \
  "${DUMP}"

echo
echo "Restore completed."

echo
echo "Post-restore sanity check: verifying row count..."

ROWCOUNT=$(psql \
  --host=database \
  --port=5432 \
  --username="${DB_USERNAME}" \
  --dbname="${DB_DATABASE_NAME}" \
  -Atc "SELECT COUNT(*) FROM assets;")

echo "assets row count: ${ROWCOUNT}"

if [ "${ROWCOUNT}" -eq 0 ]; then
  echo "ERROR: Restore completed but assets table is empty."
  exit 1
fi

echo
echo "Sanity check passed. Restore successful."
