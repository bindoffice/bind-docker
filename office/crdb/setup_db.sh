#!/bin/bash
set -euo pipefail

echo "Waiting for CockroachDB to be up..."

: "${DB_NAME:?DB_NAME is required (set via docker compose)}"

CRDB_ADDR="${CRDB_ADDR:-127.0.0.1:26257}"
HOSTPARAMS="--host ${CRDB_ADDR} --insecure"
SQL="/cockroach/cockroach.sh sql ${HOSTPARAMS}"

for i in $(seq 1 60); do
  if ${SQL} -e "SELECT 1" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

${SQL} -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
