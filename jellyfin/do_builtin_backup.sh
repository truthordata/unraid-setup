#!/usr/bin/env bash

# Because this approach limits the effectiveness of restic's file management,
# and a manual backup is relatively easy, we wont generally use this; just kept it here
# for reference

set -euo pipefail

source /mnt/user/secrets/jellyfin.env

curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: MediaBrowser Token=$RESTIC_API_KEY" \
  -d '{
    "Metadata": true,
    "Trickplay": false,
    "Subtitles": true,
    "Database": true
  }' \
  "$JELLYFIN_BASE_URL/Backup/Create"
