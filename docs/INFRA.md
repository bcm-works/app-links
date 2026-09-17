## Infrastructure

This project uses [Railway](https://railway.com/) for online infrastructure.

## Initial Setup

1. Create a new `Empty project` in the Railway dashboard.
2. Drag and drop `compose.yml` onto the project canvas.
3. In the new service's `Variables` tab, add environment variables based on guidance in [.env.sample](../.env.sample).
4. Add a new `Volume` to the service and map it to `/etc/linkding/data` in the Container
5. Deploy the Railway service.
