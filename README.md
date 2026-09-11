# Links Service

This directory contains a customised self-hosted version of the [Karakeep](https://karakeep.app/) bookmarking service.

The latest stable version of [Docker](https://www.docker.com/) needs to be installed and running.

## Local Environment

Start the app containers:

```bash
bash ./bin/start.sh
```

Stop the app containers:

```bash
bash ./bin/stop.sh
```

Local app data will be stored in the Git Ignored `./storage/app` and `./storage/search` directories.

## Infrastructure and Deployment

Refer to [docs/INFRA.md](docs/INFRA.md).
