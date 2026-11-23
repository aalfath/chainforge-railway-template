#!/usr/bin/env bash
# Railway start script for ChainForge: checks the settings, hands the volume to
# the app user, starts ChainForge on loopback and Caddy (password + /healthz) on
# $PORT, and exits non-zero if either stops, so Railway restarts the service.
set -euo pipefail
log() { echo "[chainforge-railway] $*"; }

export DATA_DIR="${DATA_DIR:-/data}"
export CF_INTERNAL_PORT="${CF_INTERNAL_PORT:-8001}"
export PORT="${PORT:-8080}"

# ---- volume ownership, then drop root ----------------------------------------
if [ "$(id -u)" = "0" ]; then
  mkdir -p "$DATA_DIR/chainforge"
  # Railway mounts volumes owned by root: hand it to the app user (1000).
  find "$DATA_DIR" -xdev \( ! -user 1000 -o ! -group 1000 \) -exec chown 1000:1000 {} + 2>/dev/null || true
  exec setpriv --reuid=1000 --regid=1000 --init-groups "$0" "$@"
fi

# ---- checks -------------------------------------------------------------------
pw="${CHAINFORGE_PASSWORD:-}"
if [ "${#pw}" -lt 12 ]; then
  log "CHAINFORGE_PASSWORD must be set and at least 12 characters; refusing to start without a password."
  exit 1
fi
export CF_USERNAME="${CHAINFORGE_USERNAME:-admin}"
case "$CF_USERNAME" in
  *[!A-Za-z0-9._@-]*|"") log "CHAINFORGE_USERNAME may only use letters, digits and ._@-"; exit 1 ;;
esac
if [ -z "${OPENAI_API_KEY:-}" ]; then
  log "OPENAI_API_KEY is empty: ChainForge opens, but OpenAI models only answer once you add a key (variable or Settings)."
fi
# An empty base URL would be sent to the browser as "", so drop it instead.
[ -z "${OPENAI_BASE_URL:-}" ] && unset OPENAI_BASE_URL

# Small-plan friendly (Railway Free/Trial: 0.5 GB RAM, 1 vCPU per service).
export MALLOC_ARENA_MAX="${MALLOC_ARENA_MAX:-2}"
export OMP_NUM_THREADS="${OMP_NUM_THREADS:-1}"
export HOME="$DATA_DIR"

CF_PASSWORD_HASH="$(printf '%s' "$pw" | caddy hash-password)"
pw=""

# ---- start --------------------------------------------------------------------
# ChainForge never sees the front-end password.
env -u CHAINFORGE_PASSWORD chainforge serve --host 127.0.0.1 --port "$CF_INTERNAL_PORT" \
  --dir "$DATA_DIR/chainforge" &
cf_pid=$!

# Caddy gets only what it needs.
env -i PATH="$PATH" HOME=/tmp XDG_DATA_HOME=/tmp/caddy XDG_CONFIG_HOME=/tmp/caddy \
  PORT="$PORT" CF_INTERNAL_PORT="$CF_INTERNAL_PORT" CF_USERNAME="$CF_USERNAME" CF_PASSWORD_HASH="$CF_PASSWORD_HASH" \
  caddy run --config /etc/chainforge-railway/Caddyfile --adapter caddyfile &
caddy_pid=$!

stopping=0
on_term() {
  stopping=1
  kill -TERM "$cf_pid" "$caddy_pid" 2>/dev/null || true
}
trap on_term TERM INT

# Poll rather than `wait -n`, so the first child to stop is always noticed.
while kill -0 "$cf_pid" 2>/dev/null && kill -0 "$caddy_pid" 2>/dev/null; do
  sleep 2 & wait $! || true
done
if [ "$stopping" = "1" ]; then
  wait 2>/dev/null || true
  exit 0
fi
if kill -0 "$cf_pid" 2>/dev/null; then who=caddy; pid=$caddy_pid; else who=chainforge; pid=$cf_pid; fi
set +e; wait "$pid"; code=$?; set -e
log "$who stopped unexpectedly (exit $code); stopping the container so Railway restarts it."
kill -TERM "$cf_pid" "$caddy_pid" 2>/dev/null || true
sleep 2
kill -KILL "$cf_pid" "$caddy_pid" 2>/dev/null || true
[ "$code" = "0" ] && code=1
exit "$code"
