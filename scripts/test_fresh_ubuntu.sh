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
SOCKET="${TEST_SOCKET:-}"
if [[ -z "$SOCKET" ]]; then
  if [[ -S /var/run/docker.sock ]]; then
    SOCKET=/var/run/docker.sock
  elif [[ -S "/run/user/$(id -u)/docker.sock" ]]; then
    SOCKET="/run/user/$(id -u)/docker.sock"
  else
    echo "[test] Could not locate a Docker socket. Set TEST_SOCKET=/path/to/docker.sock" >&2
    exit 1
  fi
fi

SOCK_GID=$(stat -c '%g' "$SOCKET")
if [[ "${TEST_PRIVILEGED:-}" == "1" ]]; then FLAGS+=( --privileged ); fi
docker run "${FLAGS[@]}" \
  --group-add "$SOCK_GID" \
  -u 0:0 \
  -e COMPOSE_PROJECT_NAME=homelab-test \
  -e COMPOSE_PROFILES="${COMPOSE_PROFILES:-}" \
  -e DOCKER_HOST=unix:///tmp/docker.sock \
  -v "$SOCKET":/tmp/docker.sock \
  -v "$ROOT_DIR":"/workspace" \
  -w /workspace \
  "$IMAGE" bash -lc "\
    apt-get update -y && \
    apt-get install -y curl ca-certificates gnupg lsb-release && \
    ./scripts/bootstrap.sh --no-sudo --cli-only"

status=$?
if [[ $status -ne 0 ]]; then
  echo "[test] Fresh-server test failed with status $status" >&2
  echo "[test] If you see 'permission denied' on the Docker socket, try:" >&2
  echo "       sudo usermod -aG docker \"$USER\" && newgrp docker" >&2
  echo "       Or run with elevated privileges (TEST_PRIVILEGED=1 make test-fresh)." >&2
  echo "       If you use rootless Docker, set TEST_SOCKET=/run/user/$(id -u)/docker.sock" >&2
  exit $status
fi
