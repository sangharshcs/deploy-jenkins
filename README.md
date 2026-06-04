# deploy-jenkins

Modern Jenkins controller + swarm worker deployment for Docker Swarm, with explicit log checks after startup.

## Why this flow

- Replaces old Make-based orchestration with script-based deploys.
- Uses unique image tags per deploy to avoid stale `latest` image confusion.
- Fails fast with actionable logs instead of waiting on blind loops.
- Keeps plugin surface minimal (`swarm` only).

## Prerequisites

- Docker Engine with Swarm mode active (`docker info` shows `Swarm.LocalNodeState=active`).
- Access to pull base images/plugins.
- Write permissions to `CONTROLLER_ROOT` and `WORKER_ROOT`.

## Quick start

1) Create `.env` from the example:

```bash
cp .env.example .env
```

2) Edit `.env` and set at least:

- `JENKINS_SERVER_IP`
- `JENKINS_USER`
- `JENKINS_PASS`

Optional useful values:

- `DOCKERHUB_NAMESPACE` (defaults to `sangharshcs`)
- `CONTROLLER_IMAGE_REPO` (defaults to `<namespace>/jenkins-controller`)
- `WORKER_IMAGE_REPO` (defaults to `<namespace>/jenkins-worker`)
- `WORKER_REPLICAS` (defaults to `1`)
- `ROTATE_SECRETS=1` (forces secret recreation on deploy)

Default image names:

- `${CONTROLLER_IMAGE_REPO}:${DEPLOY_TAG}`
- `${WORKER_IMAGE_REPO}:${DEPLOY_TAG}`

3) Deploy:

```bash
./scripts/deploy.sh
```

The script will:

- build controller/worker images with a unique local tag,
- deploy controller and wait for `/jenkins/login` to return HTTP 200,
- deploy worker and inspect logs for `403`, `RetryException`, and other startup errors,
- fail quickly and print service logs when unhealthy.

## Useful commands

```bash
# Build only
./scripts/build.sh

# Deploy without rebuild (uses current controller/worker image env values)
SKIP_BUILD=1 ./scripts/deploy.sh

# Show recent service logs
./scripts/logs.sh

# Stop controller/worker services
./scripts/stop.sh

# Push built images to Docker Hub
./scripts/push.sh
```

Push latest tags too:

```bash
PUSH_LATEST=1 ./scripts/push.sh
```

## GitHub Actions CI/CD

This repository includes `.github/workflows/docker-images.yml` to:

- build controller/worker images,
- run a container-level smoke test (controller login + worker auto-connect),
- push images to Docker Hub for `main`/`master` and `v*` tags.

Configure these repository secrets:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

Optional repository variable:

- `DOCKERHUB_NAMESPACE` (defaults to `<github-owner>`)
- `CONTROLLER_IMAGE_REPO` (optional explicit override)
- `WORKER_IMAGE_REPO` (optional explicit override)

## Local Docker Desktop note

If `JENKINS_SERVER_IP` is `127.0.0.1` or `localhost`, worker auto-targets `host.docker.internal` for controller access.

## Security notes

- Do not commit credentials.
- Jenkins credentials are mounted through Docker secrets (`jenkins-user`, `jenkins-pass`).
- Host directories are created with restrictive permissions (`750`).
- Jenkins anonymous read is disabled by default in bootstrap config.