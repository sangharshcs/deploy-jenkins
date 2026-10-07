# Changelog

## 1.4.1 - 2026-10-07

- `deploy.sh` now exports `SWARM_EXECUTORS`, `SWARM_LABELS` and `SWARM_WEBSOCKET`, so values set in `.env` reach the stack. Before, they were ignored and the `stack.yml` defaults were used.
- Shortened comments in `stack.yml`, `security.groovy`, `deploy.sh` and `AGENTS.md`; removed the unused `ROTATE_SECRETS` warning and a local path from `AGENTS.md`.
- README: removed or softened claims that were not tested, and added the scale-down results.

## 1.4.0 - 2026-10-07

- The built-in node now has 0 executors (`security.groovy`), so builds do not run inside the controller container. Unlabelled jobs run on any worker. Jobs that require the label `built-in` will wait in the queue.
- CI checks that the built-in node reports 0 executors.

## 1.3.0 - 2026-10-07

- The worker now runs as UID/GID 10001 (`jenkins`) instead of root. Jobs that install packages or write to system paths will fail; see the README for options.
- The Swarm client JAR moved from `/opt/swarm-client.jar` to `/home/jenkins/swarm-client.jar`.
- CI checks that the worker is not running as root.

## 1.2.0 - 2026-10-06

- `AGENT_USER` and `AGENT_PASS` are now required in `.env`. Add both and redeploy.
- Four Docker secrets: the admin pair stays on the controller; the agent pair goes to the controller and the workers.
- `FullControlOnceLoggedIn` replaced by matrix authorization (adds the `matrix-auth` plugin). The agent account has `Hudson.READ` and `Computer.CREATE/CONNECT/DISCONNECT/BUILD`.
- The Docker socket is no longer mounted by default and `user: root` is gone from `stack.yml`.
- `JENKINS_URL_SCHEME` and `SWARM_DISABLE_SSL_VERIFY` removed. For HTTPS, put a TLS-terminating proxy in front and set `JENKINS_CONTROLLER_URL`.
- Worker workspaces now live in each container instead of a shared host directory.
- `deploy.sh` checks that UID 1000 can write to `CONTROLLER_ROOT`; `stop.sh` reads `STACK_NAME` from `.env`.
- Controller placement constraint `node.role == manager` added. It does not pin the controller to one node.
- CI checks admin `/manage` returns 200 and agent `/manage` returns 403.

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
