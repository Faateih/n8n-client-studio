#!/usr/bin/env bash
# export-workflows.sh
#
# Exports all active workflows from the local n8n instance via the n8n API.
# Each workflow is saved as a JSON file in the matching client folder, or in
# shared/subworkflows/ if no client match is found.
#
# Usage:
#   ./scripts/export-workflows.sh
#   ./scripts/export-workflows.sh --client example-client
#
# Requirements:
#   - n8n running locally (docker compose up -d)
#   - curl, jq
#   - .env file with N8N_API_KEY, N8N_PORT

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$ROOT_DIR/.env"
ENV_PARENT="$ROOT_DIR/../.env"

# Parent .env first, then repo .env overrides
if [[ -f "$ENV_PARENT" ]]; then
  # shellcheck disable=SC1090
  set -a; source "$ENV_PARENT"; set +a
fi
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  set -a; source "$ENV_FILE"; set +a
fi

N8N_HOST="${N8N_HOST:-localhost}"
N8N_PORT="${N8N_PORT:-5678}"
N8N_BASE_URL="http://${N8N_HOST}:${N8N_PORT}"
CLIENT_FILTER=""

# ── Parse args ────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --client)
      CLIENT_FILTER="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: $0 [--client <client-folder-name>]"
      exit 1
      ;;
  esac
done

# ── Helpers ───────────────────────────────────────────────────────────────────
check_deps() {
  for cmd in curl jq; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "Error: $cmd is required but not installed."
      exit 1
    fi
  done
}

require_api_key() {
  if [[ -z "${N8N_API_KEY:-}" ]]; then
    echo "Error: N8N_API_KEY is not set."
    echo ""
    echo "The n8n REST API requires header X-N8N-API-KEY."
    echo "  1. Open n8n → Settings → API → Create an API key"
    echo "  2. Add N8N_API_KEY=... to ${ENV_FILE} or ${ENV_PARENT}"
    exit 1
  fi
}

n8n_api() {
  curl -s \
    -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
    -H "Accept: application/json" \
    "$@"
}

slugify() {
  echo "$1" | tr '[:upper:]' '[:space:]' | tr ' ' '-' | tr -cd '[:alnum:]-' | sed 's/--*/-/g' | sed 's/^-//;s/-$//'
}

# ── Main ──────────────────────────────────────────────────────────────────────
check_deps
require_api_key

echo "Connecting to n8n at $N8N_BASE_URL ..."

# Fetch all workflows
WORKFLOWS=$(n8n_api "${N8N_BASE_URL}/api/v1/workflows?limit=100")

if ! echo "$WORKFLOWS" | jq -e '.data | type == "array"' &>/dev/null; then
  echo "Error: could not list workflows. Is n8n running? Is N8N_API_KEY set in .env?"
  echo "Response: $WORKFLOWS"
  exit 1
fi

COUNT=$(echo "$WORKFLOWS" | jq '(.data // []) | length')
echo "Found $COUNT workflow(s)"

echo "$WORKFLOWS" | jq -c '(.data // [])[]' | while IFS= read -r workflow; do
  WF_ID=$(echo "$workflow" | jq -r '.id')
  WF_NAME=$(echo "$workflow" | jq -r '.name')
  WF_SLUG=$(slugify "$WF_NAME")

  # Fetch full workflow (includes nodes)
  FULL_WF=$(n8n_api "${N8N_BASE_URL}/api/v1/workflows/${WF_ID}")

  # Determine output directory
  # Look for a matching client folder (name contains the workflow slug or vice versa)
  OUT_DIR="$ROOT_DIR/shared/subworkflows"
  for client_dir in "$ROOT_DIR"/clients/*/; do
    client_name=$(basename "$client_dir")
    if [[ -n "$CLIENT_FILTER" && "$client_name" != "$CLIENT_FILTER" ]]; then
      continue
    fi
    # Simple heuristic: workflow name contains client folder name or is in client README
    if [[ "$WF_SLUG" == *"$client_name"* ]] || \
       grep -qr "$WF_NAME" "$client_dir" 2>/dev/null || \
       grep -qr "$WF_SLUG" "$client_dir" 2>/dev/null; then
      OUT_DIR="$client_dir/workflows"
      break
    fi
  done

  # If --client specified and no match found, skip
  if [[ -n "$CLIENT_FILTER" && "$OUT_DIR" == "$ROOT_DIR/shared/subworkflows" ]]; then
    echo "  Skipping '$WF_NAME' (no match for client '$CLIENT_FILTER')"
    continue
  fi

  mkdir -p "$OUT_DIR"
  OUT_FILE="$OUT_DIR/${WF_SLUG}.json"
  echo "$FULL_WF" | jq '.' > "$OUT_FILE"
  echo "  ✓ Exported '$WF_NAME' → $OUT_FILE"
done

echo ""
echo "Export complete. Review the files above, then:"
echo "  git add clients/ shared/"
echo "  git commit -m 'chore: export workflows $(date +%Y-%m-%d)'"
