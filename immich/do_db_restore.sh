docker compose stop immich-server
docker compose run --rm immich-db-dump /scripts/db_restore.sh
docker compose start immich-server