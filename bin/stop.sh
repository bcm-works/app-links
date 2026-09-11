#!/usr/bin/env bash

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

docker compose \
  --file "$REPO/compose.yml" \
  --file "$REPO/compose.local.yml" \
  down
