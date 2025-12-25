#!/bin/sh
set -e

echo "Pruning old dumps (keeping last $DB_DUMP_RETENTION)..."

i=0
for f in $(ls -1t /db_dumps/immich-*.dump 2>/dev/null || true); do
  i=$((i + 1))
  if [ "$i" -gt "$DB_DUMP_RETENTION" ]; then
    rm -f "$f"
  fi
done

echo "Creating new dump..."
pg_dump \
  --host=database \
  --port=5432 \
  --username="$DB_USERNAME" \
  --dbname="$DB_DATABASE_NAME" \
  --format=custom \
  --file="/db_dumps/immich-$(date +%Y%m%d-%H%M%S).dump"