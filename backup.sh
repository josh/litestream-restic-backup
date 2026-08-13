#!/bin/sh
set -o errexit

x() {
	echo "+ $*" >&2
	"$@"
}

db_path="${DB_PATH:-/work/db.sqlite}"
db_name="$(basename "$db_path")"

x litestream restore -force -integrity-check full "$db_path"

if [ -n "${RESTIC_AWS_ACCESS_KEY_ID:-}" ]; then
	export AWS_ACCESS_KEY_ID="$RESTIC_AWS_ACCESS_KEY_ID"
	export AWS_SECRET_ACCESS_KEY="$RESTIC_AWS_SECRET_ACCESS_KEY"
fi

if [ -n "${RESTIC_AGE_IDENTITY_FILE:-}" ]; then
	export RESTIC_PASSWORD_COMMAND="restic-age-key password"
fi

x restic backup \
	--tag "${RESTIC_TAG:-litestream}" \
	--stdin --stdin-filename "$db_name" \
	<"$db_path"
