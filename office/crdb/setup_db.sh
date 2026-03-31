#!/bin/bash
echo Wait for servers to be up
sleep 1

set -a # 将所有变量自动导出
source ./.env
set +a


CRDB_ADDR='127.0.0.1:26257';
HOSTPARAMS="--host ${CRDB_ADDR} --insecure";
SQL="/cockroach/cockroach.sh sql $HOSTPARAMS";

CREATEDB="CREATE DATABASE $DB_NAME;"

$SQL -e "$CREATEDB";
