# Changelog

## 1.2.0 - 2026-10-06

### Breaking

- `AGENT_USER` and `AGENT_PASS` are now required in `.env`; `deploy.sh` exits without them and rejects an `AGENT_USER` equal to `JENKINS_USER`. Existing deployments: add both values and redeploy.
- The worker no longer mounts the Docker socket by default and `user: root` is removed from `stack.yml`. Docker builds need the opt-in socket mount documented in `stack.yml`. The worker image itself still runs as root (it has no `USER` directive).
- `JENKINS_URL_SCHEME` is removed. For HTTPS, put a TLS-terminating reverse proxy in front of the controller and set `JENKINS_CONTROLLER_URL` explicitly. See README §HTTPS.
- `SWARM_DISABLE_SSL_VERIFY` is removed. It only affected the Java client, not the `wget` that downloads the Swarm client JAR.

### Security

- Four Docker secrets instead of two: `jenkins-user`/`jenkins-pass` go to the controller only; `agent-user`/`agent-pass` go to the controller (to create the account) and to workers. Workers never receive the admin password.
- Replaced `FullControlOnceLoggedInAuthorizationStrategy` with `GlobalMatrixAuthorizationStrategy` (adds the `matrix-auth` plugin). The agent account has only `Hudson.READ` and `Computer.CREATE/CONNECT/DISCONNECT/BUILD`.
- `security.groovy` fails fast if `agent-user` equals `jenkins-user`.
- CI smoke test asserts the admin account reaches `/manage` (HTTP 200) and the agent account is refused (HTTP 403).

### Changed

- Worker workspaces now live in each container's own filesystem instead of a shared host bind mount at `WORKER_ROOT`, so replicas cannot overwrite one another's files. Files are discarded when a replica is removed or replaced.
- `stack.yml` adds a `node.role == manager` placement constraint to the controller. It does not pin the controller to one host; on a multi-node cluster use a node label or shared storage.
- `deploy.sh` verifies that Jenkins (UID 1000) can write to `CONTROLLER_ROOT` before deploying.
- `deploy.sh` exports `JENKINS_CONTROLLER_URL` so `docker stack deploy` substitutes it from a sourced `.env`.
- `stop.sh` sources `.env`, so a `STACK_NAME` set there is honoured.
- `stop.sh` header comment now lists all four secrets.
- README documents credential rotation, HTTPS requirements and single-node limitations.
- README scale-down claims now match what was observed: an idle 5 -> 1 scale-down took the removed workers offline in Jenkins. Behaviour for a build running on a stopped replica, and whether Jenkins later removes the offline entries, are documented as untested, with a reproducible test procedure.

## 1.1.2 - 2026-06-11

- Switch worker base image from `eclipse-temurin:21-jre-ubi10-minimal` to `ubuntu:24.04` with openjdk-21 and static Docker CLI
- Add multi-arch support to worker Dockerfile via `TARGETARCH` ARG (`amd64` / `arm64`)
- Add Docker socket mount and `user: root` to worker in `stack.yml` to enable Docker-in-Docker for build jobs
- Pin swarm plugin to `swarm:3.51` in `plugins.txt` for reproducible controller builds
- Add guard in `security.groovy` to fail fast on empty secrets
- Fix missing trailing newlines in `controller/Dockerfile`, `controller/plugins.txt`, `scripts/stop.sh`, `worker/Dockerfile`
- Fix `worker/start.sh` shebang to `#!/usr/bin/env bash` for portability
- Update VERSION to `1.1.2`; correct README JDK17 → JDK21 badge and architecture diagram
- Fix hardcoded port `8080` in `AGENTS.md` validation URL to `${UI_PORT:-8080}`

## 1.1.1 - 2026-06-10

- Fixed `security.groovy` bootstrap failure caused by an incorrect `DefaultCrumbIssuer` import (`jenkins.security.csrf` → `hudson.security.csrf`), which left Jenkins unsecured on startup
- Ship `security.groovy` as `security.groovy.override` so existing `JENKINS_HOME` volumes pick up the fix on redeploy
- CI smoke test now asserts `useSecurity=true` after controller startup

## 1.1.0 - 2026-06-10

- Replaced fragmented shell scripts (`common.sh`, `build.sh`, `logs.sh`, `push.sh`, `stop.sh`)
  with a single `scripts/deploy.sh` (~60 lines) and `scripts/stop.sh` (3 lines)
- Added `stack.yml` at repo root — single Swarm stack file for controller and worker
  using native `${VAR}` env var interpolation; eliminates the `render_controller_compose`
  `sed`/`awk` placeholder hack entirely
- Worker now uses Swarm `restart_policy` (`on-failure`, delay `10s`, max `10` attempts)
  instead of a blocking 120s poll loop in the deploy script
- Removed `controller/jenkins_controller.yml` (superseded by `stack.yml`)
- Removed `scripts/common.sh`, `scripts/build.sh`, `scripts/logs.sh`, `scripts/push.sh`
- `--skip-build` flag replaces the `SKIP_BUILD=1` env var pattern
- Updated README, AGENTS.md to reflect new script surface and layout

## 1.0.0 - 2026-06-03

- Replaced legacy Make-based flow with script-based automation in `scripts/`.
- Renamed `master/slave` terminology to `controller/worker` across code and docs.
- Added Docker Hub publishing support for split repositories:
  - `jenkins-controller`
  - `jenkins-worker`
- Added GitHub Actions workflow for build, smoke-test, and image push.
- Hardened bootstrap and runtime defaults:
  - Docker secrets for Jenkins credentials
  - Crumb issuer explicitly enabled (new behavior; Jenkins API calls now require crumb handling unless using token-based flows)
