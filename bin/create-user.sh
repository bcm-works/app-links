#!/usr/bin/env bash
#
# Creates the single initial (admin) user for this single-user instance.
#
# Normal operation runs with DISABLE_SIGNUPS=true (see compose.yml), so the
# signup API is locked. This script briefly lifts the lock, performs exactly
# one signup, then restores the lock. It refuses to run when a user already
# exists, so the instance stays single-user.
#
# Local:
#
#   bash bin/create-user.sh
#
#   Flags also work: --email, --name, --password. Missing values are prompted
#   interactively (password input is hidden).
#
# Railway infrastructure:
#
#   1. In Railway, set bcm-links-web DISABLE_SIGNUPS=false and redeploy.
#   2. Run: bash bin/create-user.sh --url https://<your-public-domain>
#   3. Set DISABLE_SIGNUPS back to true and redeploy.
#

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

[ ! -f .env ] && cp .env.sample .env
source .env

bash "$REPO/bin/stop.sh"

EMAIL="${APP_USER_EMAIL:-}"
NAME="${APP_USER_NAME:-}"
PASSWORD="${APP_USER_PASSWORD:-}"
URL=""
YES=""

usage() {
  cat <<'EOF'
Usage:
  bin/create-user.sh [--email E] [--name N] [--password P] [--url BASE_URL] [--yes]

Options:
  --email E      Admin email (or APP_USER_EMAIL)
  --name N       Display name, defaults to "Admin" (or APP_USER_NAME)
  --password P   Password, min 8 chars (or APP_USER_PASSWORD; prompted if missing)
  --url URL      Remote base URL (e.g. https://xxx.up.railway.app).
                 Without --url, the local Docker Compose stack is used.
  --yes          Skip the confirmation prompt (remote mode only).
  -h, --help     Show this help.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --email) EMAIL="${2:-}"; shift 2 ;;
    --name) NAME="${2:-}"; shift 2 ;;
    --password) PASSWORD="${2:-}"; shift 2 ;;
    --url) URL="${2:-}"; shift 2 ;;
    --yes) YES="1"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

[ -z "$NAME" ] && NAME="Admin"

if [ -z "$EMAIL" ]; then
  printf 'Email: '
  read -r EMAIL
fi
if [ -z "$PASSWORD" ]; then
  printf 'Password (min 8 chars, hidden): '
  stty -echo 2>/dev/null || true
  read -r PASSWORD
  stty echo 2>/dev/null || true
  printf '\n'
fi

case "$EMAIL" in
  *@*.*) ;;
  *) echo "ERROR: '$EMAIL' does not look like an email address." >&2; exit 1 ;;
esac
if [ "${#PASSWORD}" -lt 8 ]; then
  echo "ERROR: password must be at least 8 characters." >&2
  exit 1
fi

COMPOSE=(docker compose --file "$REPO/compose.yml" --file "$REPO/compose.local.yml")

signup() {
  # $1 = base URL. Prints the raw API response body to stdout,
  # the HTTP status to stderr. Returns 0 on HTTP 200.
  local base_url="$1" payload resp_file http_code
  payload="$(python3 -c 'import json,sys; print(json.dumps({"0": {"json": {"name": sys.argv[1], "email": sys.argv[2], "password": sys.argv[3], "confirmPassword": sys.argv[3]}}}))' "$NAME" "$EMAIL" "$PASSWORD")"
  resp_file="$(mktemp)"
  http_code="$(curl -s -o "$resp_file" -w '%{http_code}' -X POST \
    "$base_url/api/trpc/users.create?batch=1" \
    -H 'Content-Type: application/json' \
    --data "$payload")"
  echo "HTTP $http_code" >&2
  cat "$resp_file"
  rm -f "$resp_file"
  [ "$http_code" = "200" ]
}

wait_for_web() {
  # $1 = base URL, waits until /api/health returns 200 (max ~90s).
  local base_url="$1" i
  for i in $(seq 1 45); do
    if [ "$(curl -s -o /dev/null -w '%{http_code}' "$base_url/api/health")" = "200" ]; then
      return 0
    fi
    sleep 2
  done
  echo "ERROR: web did not become healthy at $base_url" >&2
  return 1
}

fail_if_signup_error() {
  # $1 = raw response body. Detects Karakeep application-level failures
  # (HTTP is 200 even for FORBIDDEN) and exits non-zero with a clear message.
  local body="$1"
  if echo "$body" | grep -q '"role":"admin"'; then
    return 0
  fi
  if echo "$body" | grep -qi 'Signups are disabled'; then
    echo "ERROR: signups are currently disabled on the target instance." >&2
    echo "Local: this is a bug in the bootstrap flow, report it." >&2
    echo "Remote: set DISABLE_SIGNUPS=false on bcm-links-web, redeploy, retry." >&2
    return 1
  fi
  if echo "$body" | grep -qi 'already taken'; then
    echo "ERROR: email is already taken. Single-user instance is already provisioned; refusing to create a second user." >&2
    return 1
  fi
  echo "ERROR: signup failed. Response:" >&2
  echo "$body" >&2
  return 1
}

if [ -n "$URL" ]; then
  # ---- Remote mode (Railway): no Docker, no DB file; just the signup API. ----
  URL="${URL%/}"
  echo "Remote mode: $URL"
  echo "Make sure DISABLE_SIGNUPS=false is deployed on bcm-links-web right now,"
  echo "and that this instance has NO users yet (single-user only)."
  if [ -z "$YES" ]; then
    printf "Type the email again to confirm creating the ONE admin user: "
    read -r CONFIRM
    if [ "$CONFIRM" != "$EMAIL" ]; then
      echo "Aborted: confirmation did not match." >&2
      exit 1
    fi
  fi
  BODY="$(signup "$URL")"
  fail_if_signup_error "$BODY"
  echo "Created admin user '$EMAIL'."
  echo "NEXT: set DISABLE_SIGNUPS=true on bcm-links-web and redeploy to lock the instance."
  exit 0
fi

# ---- Local mode ----
if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Docker is not running. Start Docker and retry, or use --url for remote mode." >&2
  exit 1
fi

PORT="${KARAKEEP_PORT:-3333}"
if [ -f "$REPO/.env" ]; then
  # shellcheck disable=SC1091
  set -a; source "$REPO/.env"; set +a
  PORT="${KARAKEEP_PORT:-3333}"
fi
BASE_URL="http://localhost:${PORT}"

DB_FILE="$REPO/storage/app/db.db"
if command -v sqlite3 >/dev/null 2>&1 && [ -f "$DB_FILE" ]; then
  COUNT="$(sqlite3 "$DB_FILE" 'SELECT COUNT(*) FROM "user";' 2>/dev/null || echo "?")"
  if [ "$COUNT" != "?" ] && [ "$COUNT" -ge 1 ] 2>/dev/null; then
    echo "ERROR: $COUNT user(s) already exist in $DB_FILE. Single-user instance is already provisioned; refusing to create another." >&2
    exit 1
  fi
fi

echo "Starting local stack..."
mkdir -p "$REPO/storage/"{app,search}
"${COMPOSE[@]}" up -d >/dev/null

echo "Briefly enabling signups for the bootstrap (DISABLE_SIGNUPS=false)..."
DISABLE_SIGNUPS=false "${COMPOSE[@]}" up -d --force-recreate bcm-links-web >/dev/null
trap 'echo "Restoring signup lock (DISABLE_SIGNUPS=true)..."; "${COMPOSE[@]}" up -d --force-recreate bcm-links-web >/dev/null; wait_for_web "$BASE_URL"' EXIT
wait_for_web "$BASE_URL"

echo "Creating initial admin user '$EMAIL'..."
BODY="$(signup "$BASE_URL")"
fail_if_signup_error "$BODY"
echo "Created admin user '$EMAIL' with role admin."

# Restore the lock now (also runs via trap on failure paths after this point).
trap - EXIT
echo "Restoring signup lock (DISABLE_SIGNUPS=true)..."
"${COMPOSE[@]}" up -d --force-recreate bcm-links-web >/dev/null
wait_for_web "$BASE_URL"

LOCKED="$(docker compose --file "$REPO/compose.yml" --file "$REPO/compose.local.yml" exec bcm-links-web printenv DISABLE_SIGNUPS 2>/dev/null | tr -d '\r' || echo "?")"
if [ "$LOCKED" != "true" ]; then
  echo "WARNING: DISABLE_SIGNUPS inside the web container is '$LOCKED', expected 'true'. Signups may still be open; check compose.yml." >&2
  exit 1
fi
echo "Done. Signups are locked (DISABLE_SIGNUPS=true); single-user instance ready. Sign in at $BASE_URL."
