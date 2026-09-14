#!/bin/bash
set -euo pipefail

echo "Waiting for PostgreSQL to be up..."

: "${DB_NAME:?DB_NAME is required (set via docker compose)}"
: "${POSTGRES_USER:?POSTGRES_USER is required (set via docker compose)}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required (set via docker compose)}"

# Accept either POSTGRES_ADDR (host:port) or POSTGRES_HOST / POSTGRES_PORT.
if [ -n "${POSTGRES_ADDR:-}" ]; then
  POSTGRES_HOST="${POSTGRES_ADDR%%:*}"
  POSTGRES_PORT="${POSTGRES_ADDR##*:}"
fi
POSTGRES_HOST="${POSTGRES_HOST:-127.0.0.1}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"

export PGPASSWORD="${POSTGRES_PASSWORD}"

PSQL=(psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -v ON_ERROR_STOP=1)

ready=0
for i in $(seq 1 60); do
  if pg_isready -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 1
done

if [ "${ready}" -ne 1 ]; then
  echo "PostgreSQL not ready after 60s at ${POSTGRES_HOST}:${POSTGRES_PORT}" >&2
  exit 1
fi

echo "Creating database ${DB_NAME} if it does not exist..."
if ! "${PSQL[@]}" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}'" | grep -q 1; then
  "${PSQL[@]}" -d postgres -c "CREATE DATABASE \"${DB_NAME}\";"
fi

# Optional extra extensions, comma separated, e.g. POSTGRES_EXTENSIONS="pg_trgm,uuid-ossp"
if [ -n "${POSTGRES_EXTENSIONS:-}" ]; then
  IFS=',' read -ra EXTENSIONS <<< "${POSTGRES_EXTENSIONS}"
  for ext in "${EXTENSIONS[@]}"; do
    ext="$(echo "${ext}" | xargs)"
    [ -z "${ext}" ] && continue
    echo "Creating extension ${ext}..."
    "${PSQL[@]}" -d "${DB_NAME}" -c "CREATE EXTENSION IF NOT EXISTS \"${ext}\";"
  done
fi

echo "Database ${DB_NAME} is ready."
