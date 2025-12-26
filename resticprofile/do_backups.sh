cd ../immich
bash do_db_dump.sh
cd ../resticprofile

docker compose run --rm resticprofile backup