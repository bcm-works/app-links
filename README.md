# Links Service

This directory contains a customised self-hosted version of the [Karakeep](https://karakeep.app/) bookmarking service.

Summary of the configuration changes here:

- User signups via the app are disabled
- The single app user can be created manually by temporarily setting `DISABLE_SIGNUPS` to `false`
- Analytics are disabled
- The Docker Compose config has been altered to support the infrastructure provider's requirements

## Local Environment

### Initial Setup

- The latest stable version of [Docker](https://www.docker.com/) needs to be installed and running
- Copy [.env.sample](.env.sample) to `.env`
- Edit the Git Ignored `.env` file with suitable values
- Follow the steps in `.env` to setup the app user via the `DISABLE_SIGNUPS` variable value

### Commands

Start the app containers:

```bash
bash ./bin/start.sh
```

Stop the app containers:

```bash
bash ./bin/stop.sh
```

## Infrastructure and Deployment

Refer to [docs/INFRA.md](docs/INFRA.md).
