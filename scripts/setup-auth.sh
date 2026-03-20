#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUTH_DIR="$ROOT_DIR/auth"
DATA_DIR="$ROOT_DIR/data"
HTPASSWD_FILE="$AUTH_DIR/htpasswd"
HTPASSWD_IMAGE="${HTPASSWD_IMAGE:-httpd:2.4-alpine}"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/setup-auth.sh [username] [password]

Creates auth/htpasswd and the local data directories required by the registry.
If no username or password is provided, the script prompts for them.

Environment:
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

USERNAME="${1:-}"
PASSWORD="${2:-}"

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
  docker login localhost:5000
EOF
