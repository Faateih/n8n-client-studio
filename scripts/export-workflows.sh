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
#   - .env file with N8N_BASIC_AUTH_USER, N8N_BASIC_AUTH_PASSWORD, N8N_PORT

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$ROOT_DIR/.env"

# Load .env if it exists
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  set -a; source "$ENV_FILE"; set +a
fi

N8N_HOST="${N8N_HOST:-localhost}"
N8N_PORT="${N8N_PORT:-5678}"
N8N_USER="${N8N_BASIC_AUTH_USER:-admin}"
N8N_PASS="${N8N_BASIC_AUTH_PASSWORD:-changeme}"
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

n8n_api() {
  curl -s -u "${N8N_USER}:${N8N_PASS}" "$@"
}

slugify() {
  echo "$1" | tr '[:upper:]' '[:space:]' | tr ' ' '-' | tr -cd '[:alnum:]-' | sed 's/--*/-/g' | sed 's/^-//;s/-$//'
}

# ── Main ──────────────────────────────────────────────────────────────────────
check_deps

echo "Connecting to n8n at $N8N_BASE_URL ..."

# Fetch all workflows
WORKFLOWS=$(n8n_api "${N8N_BASE_URL}/api/v1/workflows?limit=100")

if ! echo "$WORKFLOWS" | jq -e '.data' &>/dev/null; then
  echo "Error: could not fetch workflows. Is n8n running?"
  echo "Response: $WORKFLOWS"
  exit 1
fi

COUNT=$(echo "$WORKFLOWS" | jq '.data | length')
echo "Found $COUNT workflow(s)"

echo "$WORKFLOWS" | jq -c '.data[]' | while IFS= read -r workflow; do
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
