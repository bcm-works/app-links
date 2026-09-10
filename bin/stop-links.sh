#!/usr/bin/env bash

REPO="$(cd "$(dirname "$0")/.." pwd)"
cd "$REPO"

docker compose down
