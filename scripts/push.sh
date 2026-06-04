#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

load_env
validate_env
init_defaults

if ! docker image inspect "${CONTROLLER_IMAGE}" >/dev/null 2>&1; then
  echo "Controller image not found locally: ${CONTROLLER_IMAGE}" >&2
  echo "Run ./scripts/build.sh first or set CONTROLLER_IMAGE explicitly." >&2
  exit 1
fi

if ! docker image inspect "${WORKER_IMAGE}" >/dev/null 2>&1; then
  echo "Worker image not found locally: ${WORKER_IMAGE}" >&2
  echo "Run ./scripts/build.sh first or set WORKER_IMAGE explicitly." >&2
  exit 1
fi

echo "Pushing images:"
echo "  ${CONTROLLER_IMAGE}"
echo "  ${WORKER_IMAGE}"
echo
echo "Ensure you are authenticated with Docker Hub (docker login)."

docker push "${CONTROLLER_IMAGE}"
docker push "${WORKER_IMAGE}"

if [[ "${PUSH_LATEST:-0}" == "1" ]]; then
  CONTROLLER_LATEST="${CONTROLLER_IMAGE_REPO}:latest"
  WORKER_LATEST="${WORKER_IMAGE_REPO}:latest"
  docker tag "${CONTROLLER_IMAGE}" "${CONTROLLER_LATEST}"
  docker tag "${WORKER_IMAGE}" "${WORKER_LATEST}"
  docker push "${CONTROLLER_LATEST}"
  docker push "${WORKER_LATEST}"
  echo "Also pushed :latest tags."
fi

echo "Push complete."
