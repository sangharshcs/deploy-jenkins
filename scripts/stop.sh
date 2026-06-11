#!/usr/bin/env bash
# Usage: ./scripts/stop.sh
#
# Removes the Jenkins Swarm stack, waits until teardown completes, then
# removes Docker secrets (jenkins-user, jenkins-pass).
# Safe to run repeatedly (idempotent).

set -euo pipefail

STACK_NAME="${STACK_NAME:-jenkins}"
WAIT_SECONDS="${WAIT_SECONDS:-60}"
SECRETS=(jenkins-user jenkins-pass)

stack_exists() {
  docker stack ls --format '{{.Name}}' | grep -qx "${STACK_NAME}"
}

remove_secrets() {
  for secret in "${SECRETS[@]}"; do
    if docker secret inspect "${secret}" >/dev/null 2>&1; then
      docker secret rm "${secret}" >/dev/null
      echo "Removed secret: ${secret}"
    fi
  done
}

if stack_exists; then
  docker stack rm "${STACK_NAME}"

  for (( i=0; i<WAIT_SECONDS; i++ )); do
    sleep 1
    if ! stack_exists; then
      echo "Stack removed."
      remove_secrets
      exit 0
    fi
    [[ $(( (i+1) % 5 )) -eq 0 ]] && echo "Waiting for stack to be removed... ($((i+1))s)"
  done

  if ! stack_exists; then
    echo "Stack removed."
    remove_secrets
    exit 0
  fi

  echo "Timed out waiting for stack '${STACK_NAME}' to be removed." >&2
  exit 1
fi

echo "Stack '${STACK_NAME}' is not running."
remove_secrets
