#!/usr/bin/env bash
# Menjalankan test RLS pada Postgres sekali pakai di Docker (BUKAN project Supabase).
# Pemakaian: supabase/tests/run.sh
# Semua supabase/migrations/*.sql diterapkan berurutan, lalu supabase/tests/members_rls.sql dijalankan.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
name="rls-test-$$"
trap 'docker rm -f "$name" >/dev/null 2>&1 || true' EXIT

docker run -d --rm --name "$name" -e POSTGRES_PASSWORD=x \
  -v "$root":/work:ro postgres:17-alpine >/dev/null
for _ in $(seq 1 30); do
  docker exec "$name" pg_isready -U postgres >/dev/null 2>&1 && break
  sleep 1
done
sleep 1

psql() { docker exec -i "$name" psql -U postgres -v ON_ERROR_STOP=1 -q "$@"; }

# Stub minimal skema `auth` + role bawaan Supabase (termasuk grant default ke `authenticated`).
psql <<'SQL'
create role anon nologin;
create role authenticated nologin;
create schema auth;
create table auth.users (id uuid primary key, email text, raw_user_meta_data jsonb);
create function auth.uid() returns uuid language sql stable as
  $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
grant usage on schema auth to anon, authenticated;
grant execute on function auth.uid() to anon, authenticated;
grant usage on schema public to anon, authenticated;
alter default privileges in schema public
  grant select, insert, update, delete on tables to authenticated;
SQL

for f in "$root"/migrations/*.sql; do
  echo ">> migrasi: $(basename "$f")"
  psql -f "/work/migrations/$(basename "$f")"
done

psql -f /work/tests/members_rls.sql
