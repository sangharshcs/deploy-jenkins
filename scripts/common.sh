#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTROLLER_TEMPLATE="${ROOT_DIR}/controller/jenkins_controller.yml"
CONTROLLER_RENDERED="${ROOT_DIR}/controller/jenkins_controller_copy.yml"
VERSION_FILE="${ROOT_DIR}/VERSION"

load_env() {
  if [[ -f "${ROOT_DIR}/.env" ]]; then
    # shellcheck disable=SC1091
    source "${ROOT_DIR}/.env"
  fi
}

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required env var: ${name}" >&2
    exit 1
  fi
}

init_defaults() {
  VERSION="$(tr -d '[:space:]' < "${VERSION_FILE}")"
  if [[ -z "${VERSION}" ]]; then
    VERSION="local"
  fi

  DOCKERHUB_NAMESPACE="${DOCKERHUB_NAMESPACE:-sangharshcs}"
  CONTROLLER_IMAGE_REPO="${CONTROLLER_IMAGE_REPO:-${DOCKERHUB_NAMESPACE}/jenkins-controller}"
  WORKER_IMAGE_REPO="${WORKER_IMAGE_REPO:-${DOCKERHUB_NAMESPACE}/jenkins-worker}"
  DEPLOY_TAG="${DEPLOY_TAG:-${VERSION}-$(date +%Y%m%d%H%M%S)}"
  CONTROLLER_IMAGE="${CONTROLLER_IMAGE:-${CONTROLLER_IMAGE_REPO}:${DEPLOY_TAG}}"
  WORKER_IMAGE="${WORKER_IMAGE:-${WORKER_IMAGE_REPO}:${DEPLOY_TAG}}"

  JENKINS_URL_SCHEME="${JENKINS_URL_SCHEME:-http}"
  CONTROLLER_ROOT="${CONTROLLER_ROOT:-/opt/jenkins_home}"
  WORKER_ROOT="${WORKER_ROOT:-/opt/worker_home}"
  UI_PORT="${UI_PORT:-8080}"
  AGENTS_PORT="${AGENTS_PORT:-50000}"
  CONTROLLER_SERVICE="${CONTROLLER_SERVICE:-jenkins-controller}"
  WORKER_SERVICE="${WORKER_SERVICE:-jenkins-worker}"
  CONTROLLER_STACK_SERVICE="${CONTROLLER_STACK_SERVICE:-${CONTROLLER_SERVICE}_main}"

  JENKINS_BASE_URL="${JENKINS_URL_SCHEME}://${JENKINS_SERVER_IP}:${UI_PORT}"
  JENKINS_AGENT_HOST="${JENKINS_SERVER_IP}"
  if [[ "${JENKINS_SERVER_IP}" == "127.0.0.1" || "${JENKINS_SERVER_IP}" == "localhost" ]]; then
    JENKINS_AGENT_HOST="host.docker.internal"
  fi
  JENKINS_CONTROLLER_URL="${JENKINS_URL_SCHEME}://${JENKINS_AGENT_HOST}:${UI_PORT}/jenkins"
}

validate_env() {
  require_env "JENKINS_SERVER_IP"
  require_env "JENKINS_USER"
  require_env "JENKINS_PASS"
}

require_swarm() {
  local state
  state="$(docker info --format '{{.Swarm.LocalNodeState}}')"
  if [[ "${state}" != "active" ]]; then
    echo "Docker Swarm is not active (state=${state})" >&2
    exit 1
  fi
}

wait_http_200() {
  local url="$1"
  local attempts="${2:-30}"
  local sleep_seconds="${3:-4}"
  local i
  for ((i=1; i<=attempts; i++)); do
    if curl --location --silent --output /dev/null --write-out "%{http_code}" "${url}" | rg -q "^200$"; then
      return 0
    fi
    sleep "${sleep_seconds}"
  done
  return 1
}

render_controller_compose() {
  sed \
    -e "s#@CONTROLLER_IMAGE@#${CONTROLLER_IMAGE}#g" \
    -e "s#@CONTROLLER_ROOT@#${CONTROLLER_ROOT}#g" \
    "${CONTROLLER_TEMPLATE}" > "${CONTROLLER_RENDERED}"
}

ensure_secret() {
  local name="$1"
  local value="$2"
  if [[ "${ROTATE_SECRETS:-0}" == "1" ]]; then
    docker secret rm "${name}" >/dev/null 2>&1 || true
    sleep 1
  fi
  if ! docker secret inspect "${name}" >/dev/null 2>&1; then
    printf "%s" "${value}" | docker secret create "${name}" - >/dev/null
  fi
}

