# Changelog

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
