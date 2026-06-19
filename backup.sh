#!/bin/sh
set -o errexit

x() {
	echo "+ $*" >&2
	"$@"
}

db_path="${DB_PATH:-/work/db.sqlite}"

x litestream restore -force -integrity-check full "$db_path"

if [ -n "${RESTIC_AWS_ACCESS_KEY_ID:-}" ]; then
	export AWS_ACCESS_KEY_ID="$RESTIC_AWS_ACCESS_KEY_ID"
	export AWS_SECRET_ACCESS_KEY="$RESTIC_AWS_SECRET_ACCESS_KEY"
fi

if [ -n "${RESTIC_AGE_IDENTITY_FILE:-}" ]; then
	x restic-age-key password >/run/secrets/restic-password
	export RESTIC_PASSWORD_FILE=/run/secrets/restic-password
fi

x restic backup \
	--host "${RESTIC_HOST:-$(hostname)}" \
	--tag "${RESTIC_TAG:-litestream}" \
	"$db_path"
