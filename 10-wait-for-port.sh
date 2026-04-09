#!/usr/bin/with-contenv bash
set -eu

HOST="${WAIT_FOR_HOST:-}"
PORT="${WAIT_FOR_PORT:-}"
TIMEOUT="${WAIT_FOR_TIMEOUT:-120}"
SLEEP_SECS="${WAIT_FOR_INTERVAL:-5}"

if [ -z "$HOST" ] || [ -z "$PORT" ]; then
  echo "[custom-init] WAIT_FOR_HOST and WAIT_FOR_PORT must be set"
  exit 1
fi

if ! command -v nc >/dev/null 2>&1; then
  echo "[custom-init] nc is not installed in this container"
  exit 1
fi

echo "[custom-init] Waiting for ${HOST}:${PORT} for up to ${TIMEOUT}s..."

start_ts="$(date +%s)"

while true; do
  if nc -z "$HOST" "$PORT" >/dev/null 2>&1; then
    echo "[custom-init] ${HOST}:${PORT} is reachable"
    break
  fi

  now_ts="$(date +%s)"
  elapsed="$((now_ts - start_ts))"

  if [ "$elapsed" -ge "$TIMEOUT" ]; then
    echo "[custom-init] Timed out after ${TIMEOUT}s waiting for ${HOST}:${PORT}"
    exit 1
  fi

  echo "[custom-init] ${HOST}:${PORT} not yet reachable..."
  sleep "$SLEEP_SECS"
done
