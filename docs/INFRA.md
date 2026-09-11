## Infrastructure and Deployment

This project uses [Railway](https://railway.com/) for online infrastructure and deployment

Railway does not run `compose.yml` directly, each Compose service maps to one Railway
service in a project. 

`compose.yml` stays the single source of truth:
the same image tags and env var names are used locally and on Railway, only
the *values* of `MEILI_ADDR`, `BROWSER_WEB_URL` and `NEXTAUTH_URL` differ.

No `railway.toml`/`railway.json` is used: Config as Code is deprecated by
Railway (hard cutoff 2026-12-01, new services cannot opt in).

## Option A: Compose import (recommended)

1. Create an **Empty project** in the Railway dashboard.
2. Drag & drop **only `compose.yml`** onto the project canvas, this will create the three services and the two named volumes.
3. Apply the adjustments from "Per-service settings" and "Variables" below.
4. Deploy the service.

## Option B: Manual setup

Create an empty project, then add three services via **+ New > Docker Image**:

| Railway service     | Docker image                                              | Volumes (mount path) | Public domain |
|---------------------|-----------------------------------------------------------|----------------------|---------------|
| `bcm-links-web`     | `ghcr.io/karakeep-app/karakeep:<KARAKEEP_VERSION>`        | Yes: `/data`         | Yes, port `3000` |
| `bcm-links-browser` | `zenika/alpine-chrome:123` (see note below)               | No                   | No            |
| `bcm-links-search`  | `getmeili/meilisearch:<MEILI_VERSION>`                    | Yes: `/meili_data`   | No            |

Use the same image tags as `compose.yml` (defaults: `release` /
`v1.41.0`) so local and Railway run the same build.

### bcm-links-browser start command

Set the service start command to (single line):

```text
chromium-browser --headless --no-sandbox --disable-gpu --disable-dev-shm-usage --remote-debugging-address=:: --remote-debugging-port=9222 --hide-scrollbars
```

Why a different image than local: Railway private networking needs Chrome to
listen on IPv6 (`--remote-debugging-address=::`). The local
`karakeep-chrome` image is kept for Docker (IPv4 bridge network is fine
there). Both expose the same `BROWSER_WEB_URL` contract on port 9222.

## Variables

Set these in each service's **Variables** tab (Raw Editor accepts
`KEY=VALUE` lines). Generate secrets with `openssl rand -base64 36`.

### bcm-links-web

| Key                  | Value                                          |
|----------------------|------------------------------------------------|
| `PORT`               | `3000`                                         |
| `DATA_DIR`           | `/data`                                        |
| `NEXTAUTH_URL`       | `https://${{bcm-links-web.RAILWAY_PUBLIC_DOMAIN}}` (after generating the domain; use the actual public URL) |
| `NEXTAUTH_SECRET`    | generated random string (same contract as `.env.sample`) |
| `MEILI_ADDR`         | `http://${{bcm-links-search.RAILWAY_PRIVATE_DOMAIN}}:7700` |
| `MEILI_MASTER_KEY`   | `${{bcm-links-search.MEILI_MASTER_KEY}}` (reference variable: same key on both services) |
| `BROWSER_WEB_URL`    | `http://${{bcm-links-browser.RAILWAY_PRIVATE_DOMAIN}}:9222` |
| `DISABLE_SIGNUPS`    | `false` (or `true`; mirrors `KARAKEEP_DISABLE_SIGNUPS` locally) |
| `OPENAI_API_KEY`     | optional, enables AI tagging                   |

`${{...}}` entries are Railway reference variables; they stay in sync
automatically. If service names differ, adjust the prefixes.

### bcm-links-search

| Key                 | Value                        |
|---------------------|------------------------------|
| `MEILI_ENV`         | `production`                 |
| `MEILI_HTTP_ADDR`   | `[::]:7700` (IPv6 bind; required for private networking. Already the default in `compose.yml`, harmless locally.) |
| `MEILI_MASTER_KEY`  | generated random string (shared with web, see above) |
| `MEILI_NO_ANALYTICS`| `true`                       |

### bcm-links-browser

No variables needed.

## Networking

- Private networking is automatic: services reach each other at
  `<service-name>.railway.internal:<port>` (no `ports:` mapping needed).
- Public access: on `bcm-links-web` only, **Settings > Networking >
  Generate Domain** for container port `3000`. This replaces the local
  `"${KARAKEEP_PORT:-3333}:3000"` port mapping.
- After generating the domain, set `NEXTAUTH_URL` to the public URL
  (e.g. `https://xxx.up.railway.app`).

## Verify

1. Check **Deploy Logs** per service.
2. Open the web service's public domain; create the first (admin) account.
3. Bookmark a link and confirm crawling (browser) and search (meilisearch)
   work. `depends_on` has no Railway equivalent; on cold start the web
   service retries connections until search/browser are ready.

## Updating

- Web/search images: bump `KARAKEEP_VERSION` / `MEILI_VERSION` in `.env`
  locally, verify with `bash ./bin/start.sh`, then set the same tag on the
  Railway service image (or re-import the Compose file).
- Keep `compose.yml` and this doc in sync: it is the shared config.
