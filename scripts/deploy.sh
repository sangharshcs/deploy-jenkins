#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

load_env
validate_env
init_defaults
require_swarm

if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
  export DEPLOY_TAG CONTROLLER_IMAGE WORKER_IMAGE
  "${ROOT_DIR}/scripts/build.sh"
fi

echo "${DEPLOY_TAG}"
echo "${CONTROLLER_IMAGE}"
echo "${WORKER_IMAGE}"

DOCKER_SOCK_MOUNT="${DOCKER_SOCK_MOUNT:-1}"
WORKER_MOUNTS=(
  --mount "type=bind,source=${WORKER_ROOT},target=${WORKER_ROOT}"
)
if [[ "${DOCKER_SOCK_MOUNT}" == "1" ]]; then
  WORKER_MOUNTS+=(--mount "type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock")
fi

mkdir -p "${CONTROLLER_ROOT}" "${WORKER_ROOT}"
chmod 750 "${CONTROLLER_ROOT}" "${WORKER_ROOT}"

ensure_secret "jenkins-user" "${JENKINS_USER}"
ensure_secret "jenkins-pass" "${JENKINS_PASS}"

render_controller_compose

docker stack rm "${CONTROLLER_SERVICE}" >/dev/null 2>&1 || true
docker service rm "${WORKER_SERVICE}" >/dev/null 2>&1 || true
for _ in {1..30}; do
  running="$(docker stack ps "${CONTROLLER_SERVICE}" \
    --filter desired-state=running --format '{{.ID}}' 2>/dev/null | wc -l || true)"
  if [[ "${running}" -eq 0 ]]; then
    break
  fi
  sleep 2
done

deploy_attempts="${STACK_DEPLOY_ATTEMPTS:-3}"
deploy_sleep_seconds="${STACK_DEPLOY_RETRY_SLEEP_SECONDS:-3}"
deploy_succeeded=0
for ((deploy_attempt=1; deploy_attempt<=deploy_attempts; deploy_attempt++)); do
  deploy_output="$(docker stack deploy --resolve-image never -c "${CONTROLLER_RENDERED}" "${CONTROLLER_SERVICE}" 2>&1)" && {
    printf "%s\n" "${deploy_output}"
    deploy_succeeded=1
    break
  }
  printf "%s\n" "${deploy_output}" >&2
  if echo "${deploy_output}" | rg -q "network .* not found"; then
    echo "Transient stack network creation race detected (${deploy_attempt}/${deploy_attempts}); retrying in ${deploy_sleep_seconds}s..."
    sleep "${deploy_sleep_seconds}"
    continue
  fi
  echo "docker stack deploy failed." >&2
  exit 1
done
if [[ "${deploy_succeeded}" != "1" ]]; then
  echo "docker stack deploy failed after ${deploy_attempts} attempts." >&2
  exit 1
fi

controller_attempts="${CONTROLLER_HEALTH_ATTEMPTS:-45}"
controller_sleep_seconds="${CONTROLLER_HEALTH_SLEEP_SECONDS:-4}"
if ! wait_http_200 "${JENKINS_BASE_URL}/jenkins/login" "${controller_attempts}" "${controller_sleep_seconds}" "Jenkins controller login endpoint"; then
  echo "Controller did not become healthy. Recent controller logs:" >&2
  docker service ps "${CONTROLLER_STACK_SERVICE}" || true
  docker service logs --tail 120 "${CONTROLLER_STACK_SERVICE}" || true
  exit 1
fi

docker service create \
  --no-resolve-image \
  --name "${WORKER_SERVICE}" \
  --replicas "${WORKER_REPLICAS:-1}" \
  -e "WORKER_ROOT=${WORKER_ROOT}" \
  -e "JENKINS_CONTROLLER_URL=${JENKINS_CONTROLLER_URL}" \
  --secret source=jenkins-user,target=jenkins-user \
  --secret source=jenkins-pass,target=jenkins-pass \
  "${WORKER_MOUNTS[@]}" \
  "${WORKER_IMAGE}" >/dev/null

sleep 5

curl_cfg="$(mktemp)"
trap 'rm -f "${curl_cfg}"' EXIT
chmod 600 "${curl_cfg}"
cat > "${curl_cfg}" <<EOF
user = "${JENKINS_USER}:${JENKINS_PASS}"
EOF

echo "Checking worker logs for startup failures..."
worker_attempts="${WORKER_CONNECT_ATTEMPTS:-24}"
worker_sleep_seconds="${WORKER_CONNECT_SLEEP_SECONDS:-5}"
for ((attempt=1; attempt<=worker_attempts; attempt++)); do
  if docker service logs --tail 100 "${WORKER_SERVICE}" 2>&1 | grep -qE "RetryException|HTTP response code: 403|SEVERE:"; then
    echo "Worker startup failure detected. Logs:" >&2
    docker service logs --tail 150 "${WORKER_SERVICE}" >&2 || true
    exit 1
  fi
  if curl --silent --config "${curl_cfg}" \
    "${JENKINS_BASE_URL}/jenkins/computer/api/json?pretty=true" | grep -qE '"totalExecutors"\s*:\s*[1-9]'; then
    echo "Worker is connected."
    echo "Jenkins URL: ${JENKINS_BASE_URL}/jenkins"
    exit 0
  fi
  echo "Waiting for worker connection (${attempt}/${worker_attempts})..."
  sleep "${worker_sleep_seconds}"
done

echo "Worker did not connect in time. Logs:" >&2
docker service ps --no-trunc "${WORKER_SERVICE}" >&2 || true
docker service logs --tail 150 "${WORKER_SERVICE}" >&2 || true
exit 1
