#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

load_env
init_defaults

echo "=== controller (${CONTROLLER_STACK_SERVICE}) ==="
docker service logs --tail "${TAIL_LINES:-120}" "${CONTROLLER_STACK_SERVICE}" || true
echo
echo "=== worker (${WORKER_SERVICE}) ==="
docker service logs --tail "${TAIL_LINES:-120}" "${WORKER_SERVICE}" || true
