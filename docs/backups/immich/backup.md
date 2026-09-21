# Immich Backup

To back up immich, we need to back up the underlying database, and the photos themselves of course.

Luckily, this is extremely easy.

## Database Backups

TL;DR, this is done for you automatically by Immich, dumped to `/mnt/user/Photos/immich/backups`.

### Details 
We need to back up the `Postgres` database, whose files technically live in `/mnt/user/appdata/immich/postgres/data` (which is the
immich docker container environment variables `APP_DATA_FOLDER` + `DB_DATA_FOLDER`)

Even though the database is technically just a bunch of files, you cannot just copy/paste the data folder; it must be
"dumped" as a special `.sql` file, which then can be similarly unpacked (under the hood, it's just calling `pg_dump` 
and `pg_restore`, which are commands that come packed inside the `postgres` container.)

### How its setup in Immich

You can find this setting in Immich in the administrative panel, under `settings` -> `Database Dump Settings`. It
includes the time (Cron schedule) and how many backups to keep. Generally we only need 1, since `restic` handles the
redundancies.

Currently, it's scheduled nightly at 2AM.

## Photo backups

TL;DR we just back up the `/mnt/user/Photos/immich` folder, which contains the raw photos organized as Immich requires, 
along with other necessary operational folders/metadata (and the nightly `Postgres` database dump).

Nothing fancy needs to be done here.


### A Note about photo originals

You can still access the raw photos in a traditional folder fashion via "/mnt/user/Photos/immich/uploads"; if you ever
needed to extract them since they are not organized in real human-accessible fashion, you could probably tell an AI agent 
to recursively extract them out of that location.