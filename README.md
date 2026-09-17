# Links Service

This directory contains a self-hosted [linkding](https://linkding.link/) bookmark service.

The local Docker setup uses linkding's official Compose configuration with the
`latest-plus` image, which includes support for local HTML snapshots.

Linkding stores its SQLite database and bookmark data in `storage/linkding`.
Existing Karakeep data in `storage/app` and `storage/search` is left untouched.

## Local Environment

### Initial Setup

- The latest stable version of [Docker](https://www.docker.com/) needs to be installed and running
- Copy [.env.sample](.env.sample) to `.env`
- Edit the Git Ignored `.env` file with suitable values, including
  `LD_SUPERUSER_NAME` and `LD_SUPERUSER_PASSWORD` for the initial user
- Keep the initial user values in `.env` for the first start; linkding ignores
  them after that user already exists

### Commands

Start the app container:

```bash
bash ./bin/start.sh
```

Stop the app containers:

```bash
bash ./bin/stop.sh
```

### Customising

Optional app-level customisations are stored in the [custom](custom/) directory.

### Infrastructure and Deployment

Refer to [docs/INFRA.md](docs/INFRA.md).
