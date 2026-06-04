# Agent Instructions

## Scope

This directory contains Docker/script automation for building and deploying:

- Jenkins controller (`controller/`)
- Jenkins swarm worker (`worker/`)

## First steps for agents

1. Work from this directory:
   - `project-neo/GHEC/EB1A/deploy-jenkins`
2. Read `.env.example` and `scripts/common.sh` before changing deploy logic.
3. Keep credentials out of source files.

## Command canon

All commands assume the current directory is `deploy-jenkins/`.

- Build images: `./scripts/build.sh`
- Deploy services: `./scripts/deploy.sh`
- Deploy without rebuild: `SKIP_BUILD=1 ./scripts/deploy.sh`
- Show service logs: `./scripts/logs.sh`
- Push images: `./scripts/push.sh`
- Stop services: `./scripts/stop.sh`

## Required environment variables

These are mandatory:

- `JENKINS_SERVER_IP`
- `JENKINS_USER`
- `JENKINS_PASS`

Optional:

- `JENKINS_URL_SCHEME` (defaults to `http`)
- `EXPOSE_AGENT_PORT` (defaults to `0`; set `1` to expose JNLP 50000)
- `DOCKER_SOCK_MOUNT` (defaults to `1`; set `0` to avoid mounting host Docker socket)
- `CONTROLLER_ROOT`, `WORKER_ROOT`
- `DOCKERHUB_NAMESPACE`
- `CONTROLLER_IMAGE_REPO`, `WORKER_IMAGE_REPO`
- `WORKER_REPLICAS`
- `ROTATE_SECRETS`

## Security invariants (do not violate)

- Never add hardcoded credentials (usernames, passwords, tokens, API keys).
- Never commit credential-bearing URLs (for example `http://user:pass@host`).
- Keep secret material in Docker secrets (`jenkins-user`, `jenkins-pass`).
- Do not reintroduce `777` permissions on Jenkins home or worker root paths.
- Do not add passwordless sudo (`NOPASSWD`) into container images.
- Treat `DOCKER_SOCK_MOUNT=1` as high-risk: it effectively grants host-level Docker control to worker jobs.

## Safe change guidance

- If you change service startup/auth flow, preserve secret consumption from `/run/secrets`.
- If you modify health checks, avoid logging sensitive values.
- If you update container images or dependencies, prefer supported LTS bases and minimal packages.

## Validation checklist after edits

Run and verify:

1. `./scripts/build.sh`
2. `./scripts/deploy.sh`
3. Jenkins UI is reachable at:
   - `${JENKINS_URL_SCHEME}://${JENKINS_SERVER_IP}:8080/jenkins`
4. Check logs immediately after startup:
   - `./scripts/logs.sh`
5. No secrets are printed in logs or committed to files.
