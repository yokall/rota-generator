#!/usr/bin/env bash

set -euo pipefail

# Resolve paths relative to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Allow overriding the env file path by providing it as the first arg
ENV_FILE="${1:-$REPO_ROOT/.env}"

if [ -f "$ENV_FILE" ]; then
  echo "Loading environment from: $ENV_FILE"
  # export all variables defined in the file
  set -a
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  set +a
else
  echo "No env file found at: $ENV_FILE (continuing with existing environment)"
fi

cd "$REPO_ROOT"

exec bin/generate_rota.pl "$@"
