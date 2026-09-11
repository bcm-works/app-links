## Infrastructure and Deployment

This project uses [Railway](https://railway.com/) for online infrastructure and deployment

## Import compose.yml

1. Create a new `Empty project` in the Railway dashboard.
2. Drag & drop `compose.yml` onto the project canvas.
3. Apply the adjustments detailed below.
4. Deploy the service.

## Service - bcm-links-browser

Set `Custom Start Command` to:

```
chromium-browser --headless --no-sandbox --disable-gpu --disable-dev-shm-usage --remote-debugging-address=:: --remote-debugging-port=9222 --hide-scrollbars
```

## Service - bcm-links-web

In the **Variables** tab, add/edit:

| Key                  | Value                                          |
|----------------------|------------------------------------------------|
| `PORT`               | `3000` (pinned; must match the domain target port below) |
| `DATA_DIR`           | `/data`                                        |
| `NEXTAUTH_URL`       | `https://${{bcm-links-web.RAILWAY_PUBLIC_DOMAIN}}` (after generating the domain, add it here, then deploy again) |
| `NEXTAUTH_SECRET`    | (refer to notes in `.env.sample`) |
| `MEILI_ADDR`         | `http://${{bcm-links-search.RAILWAY_PRIVATE_DOMAIN}}:7700` |
| `MEILI_MASTER_KEY`   | `${{bcm-links-search.MEILI_MASTER_KEY}}` |
| `BROWSER_WEB_URL`    | `http://${{bcm-links-browser.RAILWAY_PRIVATE_DOMAIN}}:9222` |
| `OPENAI_API_KEY`     | optional, enables AI tagging                   |
| `DISABLE_SIGNUPS`    | `true` (Set to `false` only for the minute it takes to run the initial-user bootstrap below, then back to `true`) |

Pinned port: the app always listens on `3000` (`PORT: "3000"` in
`compose.yml`). On Railway set `PORT=3000` in Variables AND set the public
domain target port to `3000` (numeric). Both sides must match or Railway
returns `502 Application failed to respond`.
`HOSTNAME=0.0.0.0` is already set in `compose.yml`; do not change it.

Note that the `${{...}}` syntax is to use Railway reference variables, and they will stay in sync
automatically. If service names differ, adjust the prefix values.

## Service - bcm-links-search

In the **Variables** tab, add/edit:

| Key                 | Value                        |
|---------------------|------------------------------|
| `MEILI_ENV`         | `production`                 |
| `MEILI_HTTP_ADDR`   | `[::]:7700` |
| `MEILI_MASTER_KEY`  | (refer to notes in `.env.sample`) |
| `MEILI_NO_ANALYTICS`| `true`                       |

## Volumes (required, not created by compose import)

Railway does not create volumes from `compose.yml`. Create them manually,
otherwise `/data` is ephemeral (users/bookmarks lost on redeploy) and the app
can crash on startup:

- Service `bcm-links-web`: **Settings > Volumes > Add Volume**, mount path
  `/data`.
- Service `bcm-links-search`: **Settings > Volumes > Add Volume**, mount path
  `/meili_data`.

## Networking

- Private networking is automatic: services reach each other at
  `<service-name>.railway.internal:<port>` (no `ports:` mapping needed).
- Public access: on `bcm-links-web` only, **Settings > Networking >
  Generate Domain** for container port `3000` (numeric target port). This
  replaces the local `"${KARAKEEP_PORT:-3333}:3000"` port mapping.
- After generating the domain, set `NEXTAUTH_URL` to the public URL
  (e.g. `https://xxx.up.railway.app`, no trailing slash), then redeploy.

## Troubleshooting `502 Application failed to respond`

Railway returns 502 when its edge proxy cannot reach the web container. Check
in this order:

1. **Target port**: `bcm-links-web` **Settings > Networking** target port
   must be the number `3000`, and the `PORT` variable must also be `3000`.
   Any other combination gives 502. Fix: set both to `3000`, redeploy.
2. **Deploy logs**: `bcm-links-web` must show Next.js `Ready` on port `3000`.
   Missing `NEXTAUTH_SECRET` / `MEILI_MASTER_KEY` or an unmounted `/data`
   volume crashes startup and surfaces as 502.
3. **`NEXTAUTH_URL`**: must exactly equal the public URL (`https://...`, no
   trailing slash). A mismatch does not cause 502, but causes auth redirects
   to fail after the page loads.

## Verify

1. Check **Deploy Logs** per service.
2. Create the one admin account (single-user bootstrap). On Railway the
   web container has no DB-file access, so the bootstrap goes through the
   signup API:
   1. Set `DISABLE_SIGNUPS=false` on `bcm-links-web` and redeploy.
   2. Run `bash bin/create-user.sh --url https://<public-domain>`
      (prompts for email/password, refuses on duplicate email).
   3. Set `DISABLE_SIGNUPS=true` and redeploy. The first user is admin;
      with signups locked, no second user can be created.
3. Bookmark a link and confirm crawling (browser) and search (meilisearch)
   work. `depends_on` has no Railway equivalent; on cold start the web
   service retries connections until search/browser are ready.

## Updating

- Web/search images: bump `KARAKEEP_VERSION` / `MEILI_VERSION` in `.env`
  locally, verify with `bash ./bin/start.sh`, then set the same tag on the
  Railway service image (or re-import the Compose file).
- Keep `compose.yml` and this doc in sync: it is the shared config.
