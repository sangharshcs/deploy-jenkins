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
- `AGENT_USER`
- `AGENT_PASS`

Optional:

- `JENKINS_CONTROLLER_URL` — explicit URL workers use to reach the controller; set this when TLS terminates on an external proxy at a different port/hostname
- `UI_PORT` (defaults to `8080`)
- `CONTROLLER_ROOT` (persistent host path), `WORKER_ROOT` (per-container path)
- `DOCKERHUB_NAMESPACE`
- `CONTROLLER_IMAGE_REPO`, `WORKER_IMAGE_REPO`
- `WORKER_REPLICAS`
- `SWARM_EXECUTORS`, `SWARM_LABELS`, `SWARM_WEBSOCKET`
- `STACK_NAME` (defaults to `jenkins`)
- `DEPLOY_TAG`

> To expose the JNLP agent port (`50000`), add it directly to the controller's `ports` section in `stack.yml`.
> Worker workspaces are ephemeral and isolated per replica. To enable Docker builds, add the documented socket mount in `stack.yml`; be aware this gives build jobs host-level Docker access and the agent Jenkins account does not limit what a build job can do with a root shell and a Docker socket.

## Security invariants (do not violate)

- Never add hardcoded credentials (usernames, passwords, tokens, API keys).
- Never commit credential-bearing URLs (for example `http://user:pass@host`).
- Keep secret material in Docker secrets (`jenkins-user`, `jenkins-pass`, `agent-user`, `agent-pass`).
- Workers must never mount the admin secrets (`jenkins-user`, `jenkins-pass`).
- Do not reintroduce `777` permissions on Jenkins home or worker root paths.
- Do not add passwordless sudo (`NOPASSWD`) into container images.
- Treat the Docker socket mount in `stack.yml` as high-risk: it grants host-level Docker control to every build job. When the socket is mounted, enable `user: root` as well — the two settings go together (socket access is root-equivalent on the host regardless of the container user).

## Safe change guidance

- If you change service startup/auth flow, preserve secret consumption from `/run/secrets`.
- If you modify health checks, avoid logging sensitive values.
- If you update container images or dependencies, prefer supported LTS bases and minimal packages.
- If you modify `stack.yml`, use `${VAR:-default}` syntax — do not reintroduce `@PLACEHOLDER@` style substitution.

## Validation checklist after edits

Run and verify:

1. `./scripts/deploy.sh`
2. Jenkins UI is reachable at:
   - `http://${JENKINS_SERVER_IP}:${UI_PORT:-8080}/jenkins`
3. Check logs immediately after startup:
   - `docker service logs --tail 50 jenkins_controller`
   - `docker service logs --tail 50 jenkins_worker`
4. No secrets are printed in logs or committed to files.
5. Agent account (`AGENT_USER`) cannot access `/manage` (expect 403).
6. Admin account (`JENKINS_USER`) can access `/manage` (expect 200).
7. Worker is not root: `docker exec $(docker ps -q -f name=jenkins_worker | head -1) id -u` must not print `0`.
