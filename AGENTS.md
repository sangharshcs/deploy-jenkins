# Agent Instructions

This repo builds and deploys a Jenkins controller (`controller/`) and Swarm workers (`worker/`) on Docker Swarm.

## First steps

1. Read `.env.example` and `stack.yml` before changing deploy logic.
2. Keep credentials out of source files.

## Commands

Run from the repo root.

- Build and deploy: `./scripts/deploy.sh` (`--skip-build` to reuse images)
- Stop everything and remove secrets: `./scripts/stop.sh`
- Logs: `docker service logs -f jenkins_controller` / `jenkins_worker`

## Environment variables

Required: `JENKINS_SERVER_IP`, `JENKINS_USER`, `JENKINS_PASS`, `AGENT_USER`, `AGENT_PASS`.

Optional values and defaults are in `.env.example` and the README configuration table.

## Security invariants

- No hardcoded credentials or credential-bearing URLs.
- Secret material stays in Docker secrets (`jenkins-user`, `jenkins-pass`, `agent-user`, `agent-pass`).
- Workers must never mount the admin secrets (`jenkins-user`, `jenkins-pass`).
- No `777` permissions on Jenkins home or worker root paths.
- No passwordless sudo (`NOPASSWD`) in container images.
- The Docker socket mount in `stack.yml` gives build jobs control of the host Docker daemon. Keep it opt-in.
- The built-in node keeps 0 executors, so builds do not run next to the admin secret and `JENKINS_HOME`.

## Changing things

- Keep reading secrets from `/run/secrets`.
- In `stack.yml`, use `${VAR:-default}` syntax.
- Do not log secret values.

## Checks after edits

1. `./scripts/deploy.sh`, then open `http://${JENKINS_SERVER_IP}:${UI_PORT:-8080}/jenkins`.
2. Check the controller and worker logs for errors and for printed secrets.
3. Agent account (`AGENT_USER`) gets 403 on `/manage`; admin account (`JENKINS_USER`) gets 200.
4. Worker is not root: `docker exec $(docker ps -q -f name=jenkins_worker | head -1) id -u` does not print `0`.
5. Built-in node has 0 executors: in the Script Console, `Jenkins.get().numExecutors` prints `0`.
