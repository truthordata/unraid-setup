echo "Shutting down immich to perform restore process..."
sleep 2
docker compose stop immich-server immich-machine-learning redis

echo "Shutdown complete, beginning restore process..."
docker compose run --rm immich-db-backup /scripts/db_restore.sh

echo "Services will now restart..."
sleep 2
docker compose start immich-server immich-machine-learning redis