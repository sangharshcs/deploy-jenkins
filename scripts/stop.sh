#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

load_env
init_defaults

docker service rm "${WORKER_SERVICE}" >/dev/null 2>&1 || true
docker stack rm "${CONTROLLER_SERVICE}" >/dev/null 2>&1 || true

echo "Stopped ${CONTROLLER_SERVICE} and ${WORKER_SERVICE} (if present)."
