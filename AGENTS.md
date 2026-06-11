# Agent Instructions

## Scope

This directory contains Docker/script automation for building and deploying:

- Jenkins controller (`controller/`)
- Jenkins swarm worker (`worker/`)

## First steps for agents

1. Work from this directory:
   - `project-neo/GHEC/EB1A/deploy-jenkins`
2. Read `.env.example` and `stack.yml` before changing deploy logic.
3. Keep credentials out of source files.

## Command canon

All commands assume the current directory is `deploy-jenkins/`.

- Build and deploy: `./scripts/deploy.sh`
- Deploy without rebuild: `./scripts/deploy.sh --skip-build`
- Stop all services: `./scripts/stop.sh`
- Controller logs: `docker service logs -f jenkins_controller`
- Worker logs: `docker service logs -f jenkins_worker`

## Required environment variables

These are mandatory:

- `JENKINS_SERVER_IP`
- `JENKINS_USER`
- `JENKINS_PASS`

Optional:

- `JENKINS_URL_SCHEME` (defaults to `http`)
- `UI_PORT` (defaults to `8080`)
- `CONTROLLER_ROOT`, `WORKER_ROOT`
- `DOCKERHUB_NAMESPACE`
- `CONTROLLER_IMAGE_REPO`, `WORKER_IMAGE_REPO`
- `WORKER_REPLICAS`
- `SWARM_EXECUTORS`, `SWARM_LABELS`, `SWARM_WEBSOCKET`
- `DEPLOY_TAG`

> To expose the JNLP agent port (`50000`), add it directly to the controller's `ports` section in `stack.yml`.
> To disable the Docker socket mount on workers, remove the `/var/run/docker.sock` volume entry from `stack.yml`.

## Security invariants (do not violate)

- Never add hardcoded credentials (usernames, passwords, tokens, API keys).
- Never commit credential-bearing URLs (for example `http://user:pass@host`).
- Keep secret material in Docker secrets (`jenkins-user`, `jenkins-pass`).
- Do not reintroduce `777` permissions on Jenkins home or worker root paths.
- Do not add passwordless sudo (`NOPASSWD`) into container images.
- Treat the Docker socket mount in `stack.yml` as high-risk: it effectively grants host-level Docker control to worker jobs.

## Safe change guidance

- If you change service startup/auth flow, preserve secret consumption from `/run/secrets`.
- If you modify health checks, avoid logging sensitive values.
- If you update container images or dependencies, prefer supported LTS bases and minimal packages.
- If you modify `stack.yml`, use `${VAR:-default}` syntax — do not reintroduce `@PLACEHOLDER@` style substitution.

## Validation checklist after edits

Run and verify:

1. `./scripts/deploy.sh`
2. Jenkins UI is reachable at:
   - `${JENKINS_URL_SCHEME}://${JENKINS_SERVER_IP}:${UI_PORT:-8080}/jenkins`
3. Check logs immediately after startup:
   - `docker service logs --tail 50 jenkins_controller`
   - `docker service logs --tail 50 jenkins_worker`
4. No secrets are printed in logs or committed to files.
