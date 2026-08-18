#!/bin/sh
# Postgres and this application are created in the same moment when a project is
# deployed from the template, so the first migration can arrive before the
# database has started accepting connections. Railway does not retry a failed
# pre-deploy command - the deployment stops there and is reported as failed - so
# an unreachable database is waited out here.
#
# Only the libpq connection failures are retried. A migration that fails on its
# own contents is fatal on the first attempt: repeating it would delay the error
# without changing it.
set -e

max_attempts=12
delay=5
attempt=1

while :; do
  if output=$(php artisan migrate --force 2>&1); then
    printf '%s\n' "$output"
    exit 0
  fi

  printf '%s\n' "$output" >&2

  if ! printf '%s' "$output" | grep -qE 'SQLSTATE\[08006\]|SQLSTATE\[08001\]|Connection refused|could not connect'; then
    exit 1
  fi

  if [ "$attempt" -ge "$max_attempts" ]; then
    echo "database still unreachable after $((max_attempts * delay))s" >&2
    exit 1
  fi

  echo "database is not accepting connections yet, attempt $attempt/$max_attempts, retrying in ${delay}s" >&2
  attempt=$((attempt + 1))
  sleep "$delay"
done
