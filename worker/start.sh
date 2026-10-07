#!/usr/bin/env bash

set -euo pipefail

JAR_PATH="/home/jenkins/swarm-client.jar"
USER_SECRET_FILE="/run/secrets/agent-user"
PASS_SECRET_FILE="/run/secrets/agent-pass"
SWARM_LABELS="${SWARM_LABELS:-swarm docker}"
SWARM_EXECUTORS="${SWARM_EXECUTORS:-5}"
JENKINS_CONTROLLER_URL="${JENKINS_CONTROLLER_URL:-}"
if [[ -z "${JENKINS_CONTROLLER_URL}" ]]; then
  echo "Missing JENKINS_CONTROLLER_URL" >&2
  exit 1
fi
JENKINS_URL="${JENKINS_CONTROLLER_URL%/}/"
WORKER_ROOT="${WORKER_ROOT:-/opt/worker_home}"

if [[ ! -s "${USER_SECRET_FILE}" || ! -s "${PASS_SECRET_FILE}" ]]; then
  echo "Missing agent credential secrets in /run/secrets" >&2
  exit 1
fi

if ! mkdir -p "${WORKER_ROOT}" 2>/dev/null; then
  echo "ERROR: cannot create WORKER_ROOT=${WORKER_ROOT} (UID $(id -u) lacks permission)" >&2
  exit 1
fi
if ! test -w "${WORKER_ROOT}"; then
  echo "ERROR: WORKER_ROOT=${WORKER_ROOT} is not writable (UID $(id -u) lacks permission)" >&2
  exit 1
fi

if [[ ! -f "${JAR_PATH}" ]]; then
  wget "${JENKINS_URL}swarm/swarm-client.jar" -O "${JAR_PATH}"
fi

J_USERNAME="$(<"${USER_SECRET_FILE}")"

SWARM_ARGS=(
  -url "${JENKINS_URL}"
  -username "${J_USERNAME}"
  -passwordFile "${PASS_SECRET_FILE}"
  -name "worker-${HOSTNAME}"
  -fsroot "${WORKER_ROOT}"
  -executors "${SWARM_EXECUTORS}"
  -labels "${SWARM_LABELS}"
)

if [[ "${SWARM_WEBSOCKET:-true}" == "true" ]]; then
  SWARM_ARGS+=(-webSocket)
fi

exec java -jar "${JAR_PATH}" "${SWARM_ARGS[@]}"
