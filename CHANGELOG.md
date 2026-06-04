# Changelog

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
  - Optional agent-port exposure (`EXPOSE_AGENT_PORT`)
  - Optional Docker socket mount for workers (`DOCKER_SOCK_MOUNT`)
