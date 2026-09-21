#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

compose() {
    docker compose \
        --project-directory "$PROJECT_DIR" \
        -f "$PROJECT_DIR/docker-compose.yml" \
        "$@"
}

# NOTE: requires the compose stack to be running (uses the actively running container)
echo "Preparing to execute paperless-ngx document_exporter..."
compose exec -T webserver document_exporter /usr/src/paperless/export
echo "paperless-ngx document export completed successfully!"