#!/usr/bin/env bash
# Usage: ./scripts/stop.sh
#
# Removes the Jenkins Swarm stack and waits until teardown completes.
# Safe to run repeatedly (idempotent).

set -euo pipefail

STACK_NAME="${STACK_NAME:-jenkins}"
WAIT_SECONDS="${WAIT_SECONDS:-60}"

stack_exists() {
  docker stack ls --format '{{.Name}}' | grep -qx "${STACK_NAME}"
}

if stack_exists; then
  docker stack rm "${STACK_NAME}" || true
else
  echo "Stack '${STACK_NAME}' is not running."
  exit 0
fi

for (( i=0; i<WAIT_SECONDS; i++ )); do
  if ! stack_exists; then
    echo "Stack removed."
    exit 0
  fi
  sleep 1
done

echo "Timed out waiting for stack '${STACK_NAME}' to be removed." >&2
exit 1
