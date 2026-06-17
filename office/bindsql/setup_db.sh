#!/bin/bash
set -euo pipefail

echo "Waiting for CockroachDB to be up..."

: "${DB_NAME:?DB_NAME is required (set via docker compose)}"

HOSTPARAMS="--host ${BINDSQL_ADDR} --insecure "
SQL="/bindsql/bindsql sql ${HOSTPARAMS}"

for i in $(seq 1 60); do
  if ${SQL} -e "SELECT 1" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

echo ${DB_NAME};
${SQL} -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
