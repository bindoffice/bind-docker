#!/bin/sh
#
# Install or remove the cron entry that renews the ACME certificate.
#
#   sh bin/cert-cron.sh install   # add a daily job (replaces an existing one)
#   sh bin/cert-cron.sh remove    # delete the job
#   sh bin/cert-cron.sh show      # print the installed job
#
# The job runs `make renew`, which is a no-op unless the certificate is within
# CERT_RENEW_DAYS of expiring, so running it daily is safe.
#
# .env:
#   CERT_CRON_SCHEDULE   crontab schedule for the job (default "0 3 * * *")
#
# Run this as the user that owns the Docker daemon access (usually root, or a
# user in the `docker` group), otherwise cron cannot reach the containers.

cd "$(dirname "$0")/.." || exit 1
DIR=$(pwd)

if [ -f ./.env ]; then
	set -a
	. ./.env
	set +a
fi

MARKER="# bind-docker-cert-renew:$DIR"
SCHEDULE="${CERT_CRON_SCHEDULE:-0 3 * * *}"
LOG="$DIR/logs/cert-renew.log"
ENTRY="$SCHEDULE cd $DIR && make renew >> $LOG 2>&1 $MARKER"

case "$1" in
install)
	mkdir -p "$DIR/logs"
	tmp=$(mktemp) || exit 1
	crontab -l 2>/dev/null | grep -vF "$MARKER" > "$tmp"
	printf '%s\n' "$ENTRY" >> "$tmp"
	if crontab "$tmp"; then
		echo "installed cron entry:"
		echo "  $ENTRY"
	else
		echo "failed to install cron entry" >&2
		rm -f "$tmp"
		exit 1
	fi
	rm -f "$tmp"
	;;
remove)
	tmp=$(mktemp) || exit 1
	crontab -l 2>/dev/null | grep -vF "$MARKER" > "$tmp"
	crontab "$tmp"
	rm -f "$tmp"
	echo "removed cron entry for $DIR"
	;;
show)
	crontab -l 2>/dev/null | grep -F "$MARKER" || echo "no cron entry for $DIR"
	;;
*)
	echo "usage: sh bin/cert-cron.sh install|remove|show" >&2
	exit 2
	;;
esac
