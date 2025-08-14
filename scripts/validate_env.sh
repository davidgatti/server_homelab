#!/usr/bin/env bash
set -euo pipefail

# Validate that all ${VARS} in compose.yaml exist in the chosen env file,
# and check for duplicate static IPs.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$ROOT_DIR"

ENV_FILE=".env"
if [[ ! -f "$ENV_FILE" ]]; then
  ENV_FILE=".env.example"
fi

if [[ "${1:-}" == "-f" && -n "${2:-}" ]]; then
  ENV_FILE="$2"
fi

echo "[validate] Using env file: $ENV_FILE"

if [[ ! -f "compose.yaml" ]]; then
  echo "[validate] compose.yaml not found" >&2
  exit 1
fi

missing=()
vars=$(grep -oE '\$\{[A-Z0-9_]+\}' compose.yaml | sed -E 's/\$\{([A-Z0-9_]+)\}/\1/' | sort -u)
for v in $vars; do
  if ! grep -Eq "^${v}=" "$ENV_FILE"; then
    missing+=("$v")
  fi
done

if (( ${#missing[@]} > 0 )); then
  echo "[validate] Missing variables in $ENV_FILE:" >&2
  for m in "${missing[@]}"; do
    echo "  - $m" >&2
  done
  exit 2
fi

echo "[validate] All variables present. Checking IP uniqueness..."

ips=$(grep -E '^[A-Z0-9_]*_IP=' "$ENV_FILE" | cut -d'=' -f2)
dup_ips=$(echo "$ips" | sort | uniq -d || true)

if [[ -n "$dup_ips" ]]; then
  echo "[validate] Duplicate IPs found:" >&2
  echo "$dup_ips" | sed 's/^/  - /' >&2
  exit 3
fi

echo "[validate] No duplicate IPs detected."
echo "[validate] OK"

