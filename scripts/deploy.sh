#!/usr/bin/env bash
# Usage: ./scripts/deploy.sh [--skip-build]
# Reads .env if present. Required: JENKINS_SERVER_IP, JENKINS_USER, JENKINS_PASS,
# AGENT_USER, AGENT_PASS. Optional variables are listed in the README.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Values with spaces must be quoted in .env (e.g. SWARM_LABELS="swarm docker")
[[ -f "${ROOT_DIR}/.env" ]] && source "${ROOT_DIR}/.env"

for var in JENKINS_SERVER_IP JENKINS_USER JENKINS_PASS AGENT_USER AGENT_PASS; do
  [[ -z "${!var:-}" ]] && { echo "Missing required env var: ${var}" >&2; exit 1; }
done

if [[ "${AGENT_USER}" == "${JENKINS_USER}" ]]; then
  echo "ERROR: AGENT_USER and JENKINS_USER must be different accounts." >&2
  exit 1
fi

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
export SWARM_EXECUTORS="${SWARM_EXECUTORS:-5}"
export SWARM_LABELS="${SWARM_LABELS:-swarm docker}"
export SWARM_WEBSOCKET="${SWARM_WEBSOCKET:-true}"
STACK_NAME="${STACK_NAME:-jenkins}"

# URL the workers use to reach the controller. Set JENKINS_CONTROLLER_URL yourself
# (for example an https proxy URL); otherwise it is built from JENKINS_SERVER_IP and UI_PORT.
if [[ -z "${JENKINS_CONTROLLER_URL:-}" ]]; then
  AGENT_HOST="${JENKINS_SERVER_IP}"
  [[ "${JENKINS_SERVER_IP}" == "127.0.0.1" || "${JENKINS_SERVER_IP}" == "localhost" ]] && AGENT_HOST="host.docker.internal"
  JENKINS_CONTROLLER_URL="http://${AGENT_HOST}:${UI_PORT}/jenkins"
fi
# Exported so docker stack deploy can substitute it into stack.yml.
export JENKINS_CONTROLLER_URL
JENKINS_BASE_URL="http://${JENKINS_SERVER_IP}:${UI_PORT}"

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

mkdir -p "${CONTROLLER_ROOT}"
chmod 750 "${CONTROLLER_ROOT}"

# Check that Jenkins (UID 1000) can write to CONTROLLER_ROOT, using the controller image.
if ! docker run --rm --user 1000:1000 \
    --entrypoint sh \
    -v "${CONTROLLER_ROOT}:/var/jenkins_home" \
    "${CONTROLLER_IMAGE}" \
    -c "test -w /var/jenkins_home" >/dev/null 2>&1; then
  echo "ERROR: Jenkins (UID 1000) cannot write to CONTROLLER_ROOT=${CONTROLLER_ROOT}." >&2
  echo "       Make the directory writable by UID 1000 before deploying:" >&2
  echo "         sudo chown 1000 \"${CONTROLLER_ROOT}\"" >&2
  exit 1
fi

# Secrets are created only if missing. To change them, run stop.sh and deploy again (see README).
for secret in jenkins-user jenkins-pass agent-user agent-pass; do
  if ! docker secret inspect "${secret}" >/dev/null 2>&1; then
    case "${secret}" in
      jenkins-user) val="${JENKINS_USER}" ;;
      jenkins-pass) val="${JENKINS_PASS}" ;;
      agent-user)   val="${AGENT_USER}" ;;
      agent-pass)   val="${AGENT_PASS}" ;;
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
