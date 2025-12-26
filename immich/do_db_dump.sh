docker compose stop database
docker compose run --rm immich-db-dump
docker compose start database