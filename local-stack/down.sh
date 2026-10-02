#!/usr/bin/env bash
# Stops the local stack. Add --reset to delete the database and keys too.
cd "$(dirname "$0")/.."; LOCAL="$PWD/.local"
for p in gateway postgrest; do [ -f "$LOCAL/$p.pid" ] && kill "$(cat "$LOCAL/$p.pid")" 2>/dev/null; rm -f "$LOCAL/$p.pid"; done
PG_BIN="${PG_BIN:-$( (command -v pg_ctl >/dev/null && dirname "$(command -v pg_ctl)") || ls -d /usr/lib/postgresql/*/bin 2>/dev/null | sort -V | tail -1)}"
[ -d "$LOCAL/pgdata" ] && "$PG_BIN/pg_ctl" -D "$LOCAL/pgdata" -m fast stop >/dev/null 2>&1
if [ "${1:-}" = "--reset" ]; then rm -rf "$LOCAL" local-stack/keys.env local-stack/postgrest.conf .env.local; echo "Reset."; fi
echo "Local stack stopped."
