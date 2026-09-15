#!/usr/bin/env bash

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

bash "$REPO/bin/stop.sh"

[ ! -f .env ] && cp .env.sample .env

docker compose \
  --file "$REPO/compose.yml" \
  up -d

echo "Started at http://localhost:${LD_HOST_PORT:-9090}/"
