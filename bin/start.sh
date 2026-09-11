#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

mkdir -p "$REPO/storage/"{app,search}

bash "$REPO/bin/stop.sh"

[ ! -f .env ] && cp .env.sample .env
source .env

docker compose \
  --file "$REPO/compose.yml" \
  --file "$REPO/compose.local.yml" \
  up -d

echo "Karakeep started at http://localhost:${KARAKEEP_PORT:-3333}/"
