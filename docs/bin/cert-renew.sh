#!/bin/sh
#
# Renew the ACME certificate, then install it into the TLS services.
#
# Safe to run repeatedly (for example from cron): the ACME endpoint is only
# called when the certificate nginx currently serves is close to expiring.
# That keeps us well clear of the Let's Encrypt duplicate-certificate rate
# limit (5 per week), which a naive daily renewal would run into.
#
#   sh bin/cert-renew.sh                      # renew only when close to expiry
#   CERT_FORCE_RENEW=1 sh bin/cert-renew.sh   # renew unconditionally
#
# .env:
#   DOMAIN            domain the certificate is issued for
#   CERT_RENEW_DAYS   renew when fewer than this many days are left (default 30)

cd "$(dirname "$0")/.." || exit 1

if [ ! -f ./.env ]; then
	echo ".env not found. Run 'cp env.example .env' and edit it first." >&2
	exit 1
fi

set -a # 将所有变量自动导出
. ./.env
set +a

RENEW_DAYS="${CERT_RENEW_DAYS:-30}"
CERT="nginx/certs/cert.crt"

# `openssl x509 -checkend` exits non-zero when the certificate expires within
# the given window (or when it is missing/unreadable), i.e. exactly when we
# do want to renew.
if [ -z "$CERT_FORCE_RENEW" ] && [ -f "$CERT" ] && \
	openssl x509 -in "$CERT" -checkend $((RENEW_DAYS * 86400)) -noout >/dev/null 2>&1; then
	echo "certificate for $DOMAIN is valid for more than ${RENEW_DAYS} days; nothing to do"
	exit 0
fi

echo "renewing certificate for $DOMAIN"
if ! curl -fsS -X POST -d "domain=$DOMAIN" "http://$DOMAIN/acme/renew"; then
	echo "ACME renewal request failed" >&2
	exit 1
fi
echo

sh bin/cert-distribute.sh
