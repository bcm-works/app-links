## Infrastructure and Deployment

This project uses [Railway](https://railway.com/) for online infrastructure and deployment.

## Estimated Ongoing Costs

From Railway's Dashboard Agent:

```
Based on your project configuration, here's your estimated monthly cost:

Plan: Hobby tier
Included monthly credit: $5

Services & Configuration:

bcm-links-web (1 replica, 1 vCPU, 1GB RAM) – EU West region
bcm-links-search (1 replica, 1 vCPU, 1GB RAM) – EU West region
bcm-links-browser (1 replica, 1 vCPU, 1GB RAM) – EU West region
Storage: 2 volumes, 1GB total
Cost Breakdown:

Compute: 3 services × 1 replica × $6.50/month per replica = $19.50
Volumes: 1GB storage × $0.25/GB/month = $0.25
Subtotal: $19.75
Less included credit: -$5.00
Network egress: Variable (metered separately, not included in plan ceiling)
Estimated monthly charge: ~$14.75 (before network egress)
```

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
