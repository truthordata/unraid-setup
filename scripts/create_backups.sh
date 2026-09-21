#!/usr/bin/env bash
set -euo pipefail

# paperless-ngx needs to be dumped manually, which is then backed up later by restic
cd ../paperless-ngx
bash do_backups.sh

cd ../resticprofile
bash do_backups.sh