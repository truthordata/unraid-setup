set -euo pipefail

# Load env vars
source .env

# Create directories if missing
mkdir -p ${APP_DATA_FOLDER}/cache

# Create secrets file if missing
if [ ! -f ${RESTIC_PASSWORD_TXT} ]; then
    docker compose run --rm resticprofile generate --random-key > ${RESTIC_PASSWORD_TXT}
    chmod 600 "${RESTIC_PASSWORD_TXT}"

    echo "Created a password file at ${RESTIC_PASSWORD_TXT} with password:"
    cat ${RESTIC_PASSWORD_TXT}
    echo
    echo "---!!!IMPORTANT!!!---"
    echo "SAVE THE PASSWORD SOMEWHERE (ex: password manager); YOU CANNOT ACCESS YOUR BACKUPS WITHOUT IT!!!"
    echo
fi

if ! OUTPUT=$(docker compose run --rm resticprofile init 2>&1); then
  if echo "$OUTPUT" | grep -q "config file already exists"; then
    echo "Repository already exists; No setup required."
  else
    echo "$OUTPUT" >&2
    exit 1
  fi
  exit 0
fi

echo "NOTE: ignore the printed repo location; the actual backup location is: ${LOCAL_BACKUP_FOLDER}"