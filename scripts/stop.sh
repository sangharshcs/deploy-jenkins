#!/usr/bin/env bash
set -euo pipefail
docker stack rm jenkins
echo "Stack removed."
