#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

load_env
validate_env
init_defaults

echo "Building controller image: ${CONTROLLER_IMAGE}"
docker build --no-cache -t "${CONTROLLER_IMAGE}" "${ROOT_DIR}/controller"

echo "Building worker image: ${WORKER_IMAGE}"
docker build -t "${WORKER_IMAGE}" "${ROOT_DIR}/worker"

echo "Build complete."
echo "CONTROLLER_IMAGE=${CONTROLLER_IMAGE}"
echo "WORKER_IMAGE=${WORKER_IMAGE}"
