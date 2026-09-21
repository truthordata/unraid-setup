#!/usr/bin/env bash
set -euo pipefail

SCRIPTS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

bash $SCRIPTS_DIR/../resticprofile/do_snapshot_cleanup.sh