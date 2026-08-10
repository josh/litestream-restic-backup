#!/bin/sh
set -o errexit

restic="/usr/local/libexec/restic"

if [ -z "${GOMEMLIMIT:-}" ]; then
	for f in /sys/fs/cgroup/memory.max /sys/fs/cgroup/memory/memory.limit_in_bytes; do
		[ -r "$f" ] || continue
		limit="$(cat "$f")"
		case "$limit" in
		'' | *[!0-9]*) continue ;;
		esac
		[ "$limit" -lt 576460752303423488 ] || continue
		GOMEMLIMIT="$((limit * 9 / 10))B"
		export GOMEMLIMIT
		break
	done
fi

age_identity=""
if [ -n "${RESTIC_AGE_IDENTITY_FILE:-}" ] || [ -n "${RESTIC_AGE_IDENTITY_COMMAND:-}" ]; then
	age_identity="1"
fi

if [ -n "$age_identity" ] &&
	[ -z "${RESTIC_PASSWORD:-}" ] &&
	[ -z "${RESTIC_PASSWORD_FILE:-}" ] &&
	[ -z "${RESTIC_PASSWORD_COMMAND:-}" ]; then
	RESTIC_PASSWORD_COMMAND="restic-age-key password"
	export RESTIC_PASSWORD_COMMAND
fi

if [ -n "$age_identity" ] &&
	[ -n "${RESTIC_FROM_REPOSITORY:-}" ] &&
	[ -z "${RESTIC_FROM_PASSWORD_FILE:-}" ] &&
	[ -z "${RESTIC_FROM_PASSWORD_COMMAND:-}" ]; then
	RESTIC_FROM_PASSWORD_COMMAND="restic-age-key from-password"
	export RESTIC_FROM_PASSWORD_COMMAND
fi

if [ -n "${RESTIC_AWS_ACCESS_KEY_ID:-}" ]; then
	AWS_ACCESS_KEY_ID="$RESTIC_AWS_ACCESS_KEY_ID"
	AWS_SECRET_ACCESS_KEY="${RESTIC_AWS_SECRET_ACCESS_KEY:-}"
	export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
fi

exec "$restic" "$@"
