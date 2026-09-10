#!/usr/bin/env bash

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

mkdir -p "$REPO/volume-"{links,search}

[ ! -f .env ] && cp .env.sample .env
source .env

PORT="$KARAKEEP_PORT" \
  DISABLE_SIGNUPS="$KARAKEEP_DISABLE_SIGNUPS" \
  OPENAI_API_KEY="$OPENAI_API_KEY" \
  docker compose \
  --file "$REPO/docker-compose.yml" \
  up -d

echo "Karakeep started at http://localhost:3333/"
