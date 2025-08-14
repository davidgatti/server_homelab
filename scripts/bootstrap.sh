#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/bootstrap.sh [--no-sudo] [--cli-only]
# Idempotent bootstrap: installs Docker (if needed), ensures external network,
# loads .env, and runs docker compose up.

SUDO=sudo
CLI_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --no-sudo) SUDO= ;;
    --cli-only) CLI_ONLY=1 ;;
  esac
done

here_dir() { cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P; }
ROOT_DIR="$(cd "$(here_dir)/.." && pwd -P)"
cd "$ROOT_DIR"

require_cmd() { command -v "$1" >/dev/null 2>&1; }

log() { echo "[bootstrap] $*"; }

ensure_packages() {
  if ! require_cmd apt-get; then
    log "apt-get not found. This script targets Ubuntu environments."
    return
  fi
  $SUDO apt-get update -y
  $SUDO apt-get install -y ca-certificates curl gnupg lsb-release
}

install_docker_if_needed() {
  if require_cmd docker; then
    log "Docker CLI found: $(docker --version)"
  else
    if [[ "$CLI_ONLY" -eq 1 ]]; then
      log "Installing Docker CLI + Compose plugin (cli-only mode)"
    else
      log "Installing Docker Engine and CLI"
    fi
    # Official Docker apt repo
    $SUDO install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    $SUDO chmod a+r /etc/apt/keyrings/docker.gpg
    . /etc/os-release
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $VERSION_CODENAME stable" | $SUDO tee /etc/apt/sources.list.d/docker.list >/dev/null
    $SUDO apt-get update -y
    if [[ "$CLI_ONLY" -eq 1 ]]; then
      $SUDO apt-get install -y docker-ce-cli docker-compose-plugin docker-buildx-plugin
    else
      $SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      if command -v systemctl >/dev/null 2>&1; then
        $SUDO systemctl enable --now docker || true
      fi
    fi
  fi

  if docker compose version >/dev/null 2>&1; then
    log "Docker Compose plugin ready: $(docker compose version)"
  else
    log "Installing Docker Compose plugin"
    $SUDO apt-get install -y docker-compose-plugin || true
  fi
}

ensure_env_file() {
  if [[ ! -f .env ]]; then
    log ".env not found. Copying from .env.example"
    cp .env.example .env
  fi
}

load_env() {
  # shellcheck disable=SC2046
  set -a && . ./.env && set +a
}

ensure_network() {
  local net_name="${HOMELAB_NET_NAME:-homelab}"
  if ! docker network inspect "$net_name" >/dev/null 2>&1; then
    local subnet="${HOMELAB_SUBNET:-172.24.0.0/16}"
    local gateway="${HOMELAB_GATEWAY:-172.24.0.1}"
    log "Creating external network '$net_name' ($subnet, gw $gateway)"
    docker network create "$net_name" \
      --driver bridge \
      --subnet "$subnet" \
      --gateway "$gateway"
  else
    log "External network '${net_name}' exists"
  fi
}

compose_up() {
  # Use COMPOSE_PROFILES if present in environment to enable optional services
  log "Starting services via docker compose"
  docker compose --env-file .env -f compose.yaml up -d
  docker compose --env-file .env -f compose.yaml ps
}

main() {
  ensure_packages
  install_docker_if_needed
  ensure_env_file
  load_env
  ensure_network
  compose_up
  log "Done."
}

main "$@"
