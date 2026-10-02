#!/usr/bin/env bash
# Starts Notely's local "Supabase": Postgres 17 + PostgREST + a tiny /rest/v1 gateway.
# Everything binds to 127.0.0.1 and lives in ./.local. No Docker needed.
# Needs: node 18+, Postgres 15+ server binaries (initdb, pg_ctl, psql), postgrest 12+.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"; LOCAL="$ROOT/.local"; mkdir -p "$LOCAL"
if [ -z "${PG_BIN:-}" ]; then
  if command -v pg_ctl >/dev/null; then PG_BIN="$(dirname "$(command -v pg_ctl)")"
  else PG_BIN="$(ls -d /usr/lib/postgresql/*/bin 2>/dev/null | sort -V | tail -1)"; fi
fi
[ -x "$PG_BIN/pg_ctl" ] || { echo "Postgres server binaries not found. Set PG_BIN=/path/to/postgres/bin"; exit 1; }
command -v postgrest >/dev/null || { echo "postgrest not found: https://docs.postgrest.org/en/stable/explanations/install.html"; exit 1; }
PGPORT=54322; export PGHOST=127.0.0.1 PGPORT PGUSER=postgres

[ -f local-stack/keys.env ] || node local-stack/make-keys.mjs
set -a; . local-stack/keys.env; set +a

if [ ! -d "$LOCAL/pgdata" ]; then
  "$PG_BIN/initdb" -D "$LOCAL/pgdata" -U postgres --auth=trust >/dev/null
  FRESH=1
fi
"$PG_BIN/pg_ctl" -D "$LOCAL/pgdata" -l "$LOCAL/pg.log" -o "-p $PGPORT -k $LOCAL -c listen_addresses=127.0.0.1" -w start >/dev/null
if [ "${FRESH:-}" = 1 ]; then
  "$PG_BIN/psql" -q -v ON_ERROR_STOP=1 -d postgres -c 'create database notely'
  for f in local-stack/supabase-shim.sql supabase/migrations/*.sql supabase/seed.sql; do
    "$PG_BIN/psql" -q -v ON_ERROR_STOP=1 -d notely -f "$f"
  done
fi

cat > local-stack/postgrest.conf <<CONF
db-uri = "postgres://authenticator:authenticator-local-only@127.0.0.1:$PGPORT/notely"
db-schemas = "public"
db-anon-role = "anon"
jwt-secret = "$JWT_SECRET"
server-host = "127.0.0.1"
server-port = 54330
CONF
nohup postgrest local-stack/postgrest.conf > "$LOCAL/postgrest.log" 2>&1 & echo $! > "$LOCAL/postgrest.pid"
nohup node local-stack/gateway.mjs > "$LOCAL/gateway.log" 2>&1 & echo $! > "$LOCAL/gateway.pid"

# The app's env. The service-role key under a NEXT_PUBLIC_ name is one of the planted bugs.
cat > .env.local <<ENV
NEXT_PUBLIC_SUPABASE_URL=http://127.0.0.1:54321
NEXT_PUBLIC_SUPABASE_ANON_KEY=$ANON_KEY
NEXT_PUBLIC_SUPABASE_SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY
STRIPE_SECRET_KEY=sk_test_FAKE_local_only
STRIPE_WEBHOOK_SECRET=
ENV
sleep 1
echo "Local stack up: Data API http://127.0.0.1:54321/rest/v1  (Postgres on 127.0.0.1:$PGPORT)"
echo "Wrote .env.local. Test JWTs for user A/B are in local-stack/keys.env."
echo "Next: npm install && npm run build && npm start   ->  http://127.0.0.1:3100"
