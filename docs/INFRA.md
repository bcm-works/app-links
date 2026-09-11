## Infrastructure and Deployment

This project uses [Railway](https://railway.com/) for online infrastructure and deployment

## Initial setup

1. Create a new `Empty project` in the Railway dashboard.
2. Drag and drop `compose.yml` onto the project canvas.
3. Apply the adjustments detailed below.
4. Redeploy all services.

## Service - bcm-links-browser

Set `Custom Start Command` to:

```
chromium-browser --headless --no-sandbox --disable-gpu --disable-dev-shm-usage --remote-debugging-address=:: --remote-debugging-port=9222 --hide-scrollbars
```

## Service - bcm-links-web

In the **Settings** tab, scroll down to **Public Networking**.

Generate a domain or add your own custom domain. Point this at port `3000` in the service.

In the **Variables** tab, add/edit:

| Key                  | Value                                          |
|----------------------|------------------------------------------------|
| `PORT`               | `3000` |
| `DATA_DIR`           | `/data`                                        |
| `NEXTAUTH_URL`       | (add the public domain, starting with `https://` and without a trailing `/`, then deploy again) |
| `NEXTAUTH_SECRET`    | (refer to notes in `.env.sample`) |
| `MEILI_ADDR`         | `http://${{bcm-links-search.RAILWAY_PRIVATE_DOMAIN}}:7700` |
| `MEILI_MASTER_KEY`   | (refer to notes in `.env.sample`) |
| `BROWSER_WEB_URL`    | `http://${{bcm-links-browser.RAILWAY_PRIVATE_DOMAIN}}:9222` |
| `OPENAI_API_KEY`     | (optional, enables AI tagging)                   |
| `DISABLE_SIGNUPS`    | `true` (set to `false` temporarily to create the initial user) |

## Service - bcm-links-search

In the **Variables** tab, add/edit:

| Key                 | Value                        |
|---------------------|------------------------------|
| `MEILI_ENV`         | `production`                 |
| `MEILI_HTTP_ADDR`   | `[::]:7700` |
| `MEILI_MASTER_KEY`  | (refer to notes in `.env.sample`) |
| `MEILI_NO_ANALYTICS`| `true`                       |

## Storage Volumes

Railway may not automatically create volumes from `compose.yml`, so add them manually if needed:

- Service `bcm-links-web`: **Settings > Volumes > Add Volume**, mount path
  `/data`.
- Service `bcm-links-search`: **Settings > Volumes > Add Volume**, mount path
  `/meili_data`.
