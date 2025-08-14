#!/usr/bin/env bash
set -euo pipefail

# Run the bootstrap inside a fresh Ubuntu container using the host Docker Engine.
# This simulates a brand-new server where scripts do all setup.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
IMAGE="ubuntu:24.04"

echo "[test] Pulling fresh $IMAGE if needed"
docker pull "$IMAGE"

echo "[test] Running bootstrap inside $IMAGE (host docker socket mounted)"
FLAGS=(--rm)
if [ -t 1 ]; then FLAGS+=( -it ); fi
SOCK_GID=$(stat -c '%g' /var/run/docker.sock)
if [[ "${TEST_PRIVILEGED:-}" == "1" ]]; then FLAGS+=( --privileged ); fi
docker run "${FLAGS[@]}" \
  --group-add "$SOCK_GID" \
  -u 0:0 \
  -e COMPOSE_PROFILES="${COMPOSE_PROFILES:-}" \
  -e DOCKER_HOST=unix:///var/run/docker.sock \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$ROOT_DIR":"/workspace" \
  -w /workspace \
  "$IMAGE" bash -lc "\
    apt-get update -y && \
    apt-get install -y curl ca-certificates gnupg lsb-release && \
    ./scripts/bootstrap.sh --no-sudo --cli-only"

status=$?
if [[ $status -ne 0 ]]; then
  echo "[test] Fresh-server test failed with status $status" >&2
  echo "[test] If you see 'permission denied' on /var/run/docker.sock, try:" >&2
  echo "       sudo usermod -aG docker \"$USER\" && newgrp docker" >&2
  echo "       Or run with elevated privileges, or set TEST_PRIVILEGED=1 and mount /var/run/docker.sock accordingly." >&2
  exit $status
fi
