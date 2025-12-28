#!/bin/sh
set -e



FILE_OUT="/db_dumps/immich-$(date +%Y%m%d-%H%M%S).dump"

echo "Creating new dump..."
pg_dump \
  --host=database \
  --port=5432 \
  --username="$DB_USERNAME" \
  --dbname="$DB_NAME" \
  --format=custom \
  --file=$FILE_OUT


TOC_OUTPUT=$(pg_restore -l "$FILE_OUT") || {
  echo "ERROR: Dumped archive was unreadable; removing..."
  rm "$FILE_OUT"
  exit 1
}

TOC_ENTRIES=$(echo "$TOC_OUTPUT" \
  | awk -F: '/TOC Entries/ { gsub(/^[[:space:]]+/, "", $2); print $2 }')

if [ -z "$TOC_ENTRIES" ] || [ "$TOC_ENTRIES" -eq 0 ]; then
  echo
  echo "ERROR: Dump contains no TOC entries. Aborting."
  rm "$FILE_OUT"
  exit 1
fi

echo "DB DUMP COMPLETED SUCCESSFULLY"

echo "Pruning old dumps, if needed (keeps last $DB_DUMP_RETENTION)..."
i=0
for f in $(ls -1t /db_dumps/immich-*.dump 2>/dev/null || true); do
  i=$((i + 1))
  if [ "$i" -gt "$DB_DUMP_RETENTION" ]; then
    rm -f "$f"
  fi
done
