#!/bin/sh
#
# Install the certificate issued by the ACME client into every service that
# terminates TLS, then make the running services pick it up.
#
# The ACME client writes the pair into BIND_CERT_DIR, which is bind-mounted
# from ./bindinbox/certs (office/docs) or ./bindmeet/certs (meet). Each TLS
# service mounts its own copy, so the files are copied around and the running
# services are reloaded/restarted.

cd "$(dirname "$0")/.." || exit 1

# Locate the pair produced by the ACME client.
SRC_DIR=
for d in bindinbox/certs bindmeet/certs; do
	if [ -f "$d/cert.crt" ] && [ -f "$d/cert.key" ]; then
		SRC_DIR="$d"
		break
	fi
done

if [ -z "$SRC_DIR" ]; then
	echo "no certificate found in bindinbox/certs or bindmeet/certs" >&2
	exit 1
fi

# nginx terminates HTTPS, bindsmtp SMTP/submission, bindimap IMAPS.
for dest in nginx/certs smtp/certs imap/certs; do
	[ -d "$dest" ] || continue
	\cp -f "$SRC_DIR/cert.crt" "$dest/cert.crt"
	\cp -f "$SRC_DIR/cert.key" "$dest/cert.key"
	echo "installed certificate into $dest"
done

# Only touch services this deployment actually defines.
SERVICES=$(docker compose config --services 2>/dev/null)

if printf '%s\n' "$SERVICES" | grep -qx nginx; then
	# nginx keeps the certificate in memory, so it has to be reloaded (not
	# restarted) to serve the new pair without dropping connections.
	if docker compose exec -T nginx nginx -s reload >/dev/null 2>&1; then
		echo "nginx reloaded"
	else
		echo "nginx is not running; it will use the new certificate on next start"
	fi
fi

# The mail services read the pair at startup.
for svc in bindsmtp bindimap; do
	printf '%s\n' "$SERVICES" | grep -qx "$svc" || continue
	if docker compose restart "$svc" >/dev/null 2>&1; then
		echo "$svc restarted"
	fi
done
