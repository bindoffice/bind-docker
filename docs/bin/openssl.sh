#!/bin/sh

cd "$(dirname "$0")/.." || exit 1

if [ ! -f ./.env ]; then
	echo ".env not found. Run 'cp env.example .env' and edit it first." >&2
	exit 1
fi

set -a # 将所有变量自动导出
. ./.env
set +a

CERT_DIR="nginx/certs"
CRT="$CERT_DIR/cert.crt"
KEY="$CERT_DIR/cert.key"

mkdir -p "$CERT_DIR"

if [ -f "$CRT" ] && [ -f "$KEY" ]; then
	echo "Certificates already exist at $CRT and $KEY; skipping generation."
else
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout "$KEY" \
		-out "$CRT" \
		-subj "/CN=$DOMAIN"
fi

# bindsmtp / bindimap mount their own cert dirs; keep them in sync with nginx
# (same destinations as bin/cert-distribute.sh after ACME).
for dest in smtp/certs imap/certs; do
	[ -d "$dest" ] || continue
	\cp -f "$CRT" "$dest/cert.crt"
	\cp -f "$KEY" "$dest/cert.key"
	echo "installed certificate into $dest"
done
