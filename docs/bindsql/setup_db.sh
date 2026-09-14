#!/bin/bash
set -euo pipefail

echo "Waiting for CockroachDB to be up..."

: "${DB_NAME:?DB_NAME is required (set via docker compose)}"
: "${BINDSQL_ADDR:?BINDSQL_ADDR is required (set via docker compose)}"

HOSTPARAMS="--host ${BINDSQL_ADDR} --insecure"
SQL="/bindsql/bindsql sql ${HOSTPARAMS}"

ready=0
for i in $(seq 1 60); do
  if ${SQL} -e "SELECT 1" >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 1
done

if [ "${ready}" -ne 1 ]; then
  echo "CockroachDB not ready after 60s at ${BINDSQL_ADDR}" >&2
  exit 1
fi

echo "Creating database ${DB_NAME}..."
${SQL} -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
echo "Database ${DB_NAME} is ready."
