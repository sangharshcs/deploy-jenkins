#!/usr/bin/env bash
# Usage: ./scripts/deploy.sh [--skip-build]
#
# Required env vars (or set in .env):
#   JENKINS_SERVER_IP, JENKINS_USER, JENKINS_PASS
#
# Optional: CONTROLLER_IMAGE, WORKER_IMAGE, DEPLOY_TAG, UI_PORT,
#           CONTROLLER_ROOT, WORKER_ROOT, WORKER_REPLICAS, SWARM_EXECUTORS,
#           SWARM_LABELS, SWARM_WEBSOCKET, STACK_NAME

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Values with spaces must be quoted in .env (e.g. SWARM_LABELS="swarm docker")
[[ -f "${ROOT_DIR}/.env" ]] && source "${ROOT_DIR}/.env"

# Validate required vars before any substitution that dereferences them
for var in JENKINS_SERVER_IP JENKINS_USER JENKINS_PASS; do
  [[ -z "${!var:-}" ]] && { echo "Missing required env var: ${var}" >&2; exit 1; }
done

[[ -n "${ROTATE_SECRETS:-}" ]] && echo "WARN: ROTATE_SECRETS is no longer supported. See README §Stale secrets." >&2

# Defaults
VERSION="$(tr -d '[:space:]' < "${ROOT_DIR}/VERSION" 2>/dev/null || echo "local")"
DEPLOY_TAG="${DEPLOY_TAG:-${VERSION}-$(date +%Y%m%d%H%M%S)}"
DOCKERHUB_NAMESPACE="${DOCKERHUB_NAMESPACE:-sangharshcs}"
export CONTROLLER_IMAGE="${CONTROLLER_IMAGE:-${DOCKERHUB_NAMESPACE}/jenkins-controller:${DEPLOY_TAG}}"
export WORKER_IMAGE="${WORKER_IMAGE:-${DOCKERHUB_NAMESPACE}/jenkins-worker:${DEPLOY_TAG}}"
export UI_PORT="${UI_PORT:-8080}"
export CONTROLLER_ROOT="${CONTROLLER_ROOT:-/opt/jenkins_home}"
export WORKER_ROOT="${WORKER_ROOT:-/opt/worker_home}"
export WORKER_REPLICAS="${WORKER_REPLICAS:-1}"
STACK_NAME="${STACK_NAME:-jenkins}"

# Derive controller URL (handle localhost -> host.docker.internal for worker)
AGENT_HOST="${JENKINS_SERVER_IP}"
[[ "${JENKINS_SERVER_IP}" == "127.0.0.1" || "${JENKINS_SERVER_IP}" == "localhost" ]] && AGENT_HOST="host.docker.internal"
export JENKINS_CONTROLLER_URL="${JENKINS_URL_SCHEME:-http}://${AGENT_HOST}:${UI_PORT}/jenkins"
JENKINS_BASE_URL="${JENKINS_URL_SCHEME:-http}://${JENKINS_SERVER_IP}:${UI_PORT}"

# Check swarm is active
state="$(docker info --format '{{.Swarm.LocalNodeState}}')"
[[ "${state}" != "active" ]] && { echo "Docker Swarm is not active (state=${state})" >&2; exit 1; }

# Build images unless skipped
if [[ "${1:-}" != "--skip-build" ]]; then
  echo "Building controller: ${CONTROLLER_IMAGE}"
  docker build --no-cache -t "${CONTROLLER_IMAGE}" "${ROOT_DIR}/controller"
  echo "Building worker: ${WORKER_IMAGE}"
  docker build -t "${WORKER_IMAGE}" "${ROOT_DIR}/worker"
fi

# Create host directories
mkdir -p "${CONTROLLER_ROOT}" "${WORKER_ROOT}"
chmod 750 "${CONTROLLER_ROOT}" "${WORKER_ROOT}"

# Create secrets if they don't exist
for secret in jenkins-user jenkins-pass; do
  if ! docker secret inspect "${secret}" >/dev/null 2>&1; then
    case "${secret}" in
      jenkins-user) val="${JENKINS_USER}" ;;
      jenkins-pass) val="${JENKINS_PASS}" ;;
      *) echo "Unknown secret: ${secret}" >&2; exit 1 ;;
    esac
    printf "%s" "${val}" | docker secret create "${secret}" - >/dev/null
    echo "Created secret: ${secret}"
  fi
done

# Deploy stack
echo "Deploying stack..."
docker stack deploy --resolve-image never -c "${ROOT_DIR}/stack.yml" "${STACK_NAME}"

echo ""
echo "Jenkins will be available at: ${JENKINS_BASE_URL}/jenkins"
echo "Monitor with: docker stack ps ${STACK_NAME}"
echo "Logs:         docker service logs -f ${STACK_NAME}_controller"
