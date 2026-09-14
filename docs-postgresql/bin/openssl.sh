#!/bin/bash

set -a # 将所有变量自动导出
source ./.env
set +a

CERT_DIR="nginx/certs"
CRT="$CERT_DIR/cert.crt"
KEY="$CERT_DIR/cert.key"

if [[ -f "$CRT" && -f "$KEY" ]]; then
	echo "Certificates already exist at $CRT and $KEY; skipping generation."
	exit 0
fi

mkdir -p "$CERT_DIR"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-keyout "$KEY" \
	-out "$CRT" \
	-subj "/CN=$DOMAIN"
