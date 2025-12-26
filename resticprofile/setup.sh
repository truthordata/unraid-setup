set -euo pipefail

# Load env vars
source .env

# Create directories if missing
mkdir -p ${APP_DATA_FOLDER}/cache
mkdir -p ${APP_DATA_FOLDER}/config

# Create secrets file if missing
if [ ! -f ${SECRETS_ENV_FILE} ]; then
    docker compose run --rm resticprofile generate --random-key > ${SECRETS_ENV_FILE}
    chmod 600 "${SECRETS_ENV_FILE}"

    echo "Created a password file at ${SECRETS_ENV_FILE} with password:"
    cat ${SECRETS_ENV_FILE}
    echo
    echo "SAVE THIS PASSWORD SOMEWHERE (ex: password manager); YOU CANNOT ACCESS YOUR BACKUPS WITHOUT IT!!!"
fi