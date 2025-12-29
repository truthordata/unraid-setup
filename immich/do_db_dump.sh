echo "Shutting down immich to perform db dump process..."
sleep 2
docker compose stop immich-server

echo "Shutdown complete, beginning db dump process..."
docker compose run --rm immich-db-backup /scripts/db_dump.sh

echo "Services will now restart..."
sleep 2
docker compose start immich-server