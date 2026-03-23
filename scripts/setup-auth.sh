#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HTPASSWD_IMAGE="${HTPASSWD_IMAGE:-httpd:2.4-alpine}"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env}"

resolve_path() {
  local path="$1"

  if [[ "$path" = /* ]]; then
    printf '%s\n' "$path"
  else
    printf '%s\n' "$ROOT_DIR/${path#./}"
  fi
}

usage() {
  cat <<'EOF'
Usage:
  ./scripts/setup-auth.sh [username] [password]

Creates auth/htpasswd and the local data directories required by the registry.
If no username or password is provided, the script prompts for them.

Environment:
  ENV_FILE         Override the environment file path (default: ./.env)
  HTPASSWD_IMAGE   Override the Docker image used to generate htpasswd
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -gt 2 ]]; then
  usage
  exit 1
fi

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  set +a
fi

USERNAME="${1:-${REGISTRY_USERNAME:-}}"
PASSWORD="${2:-${REGISTRY_PASSWORD:-}}"
LOGIN_HOST="${REGISTRY_LOGIN_HOST:-localhost}"
LOGIN_PORT="${REGISTRY_PORT:-5000}"
AUTH_DIR="$(resolve_path "${REGISTRY_AUTH_DIR:-./auth}")"
DATA_DIR="$(resolve_path "${REGISTRY_DATA_DIR:-./data}")"
HTPASSWD_FILE="$AUTH_DIR/htpasswd"

if [[ -z "$USERNAME" ]]; then
  read -r -p "Registry username: " USERNAME
fi

if [[ -z "$PASSWORD" ]]; then
  read -r -s -p "Registry password: " PASSWORD
  printf '\n'
fi

if [[ -z "$USERNAME" || -z "$PASSWORD" ]]; then
  printf 'Username and password are required.\n' >&2
  exit 1
fi

mkdir -p "$AUTH_DIR" "$DATA_DIR"

docker run --rm --entrypoint htpasswd "$HTPASSWD_IMAGE" -Bbn "$USERNAME" "$PASSWORD" > "$HTPASSWD_FILE"

chmod 640 "$HTPASSWD_FILE"

cat <<EOF
Registry bootstrap complete.

- Credentials file: $HTPASSWD_FILE
- Data directory: $DATA_DIR

Next:
  docker compose up -d
  docker login ${LOGIN_HOST}:${LOGIN_PORT}
EOF
