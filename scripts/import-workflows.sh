#!/usr/bin/env bash
# import-workflows.sh
#
# Imports one or more workflow JSON files into the local n8n instance.
#
# Usage:
#   ./scripts/import-workflows.sh <path/to/workflow.json> [<another.json> ...]
#   ./scripts/import-workflows.sh clients/example-client/workflows/lead-intake-test.json
#
# The workflow is created if it does not exist, or updated if a workflow with
# the same name already exists.
#
# Requirements:
#   - n8n running locally (docker compose up -d)
#   - curl, jq

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$ROOT_DIR/.env"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  set -a; source "$ENV_FILE"; set +a
fi

N8N_HOST="${N8N_HOST:-localhost}"
N8N_PORT="${N8N_PORT:-5678}"
N8N_USER="${N8N_BASIC_AUTH_USER:-admin}"
N8N_PASS="${N8N_BASIC_AUTH_PASSWORD:-changeme}"
N8N_BASE_URL="http://${N8N_HOST}:${N8N_PORT}"

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

import_workflow() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    echo "  ✗ File not found: $file"
    return 1
  fi

  local wf_name
  wf_name=$(jq -r '.name // "unknown"' "$file")

  echo "  Importing '$wf_name' from $file ..."

  # Check if a workflow with this name already exists
  local existing_id
  existing_id=$(n8n_api "${N8N_BASE_URL}/api/v1/workflows?limit=100" \
    | jq -r --arg name "$wf_name" '.data[] | select(.name == $name) | .id' | head -1)

  if [[ -n "$existing_id" ]]; then
    echo "  Found existing workflow (id: $existing_id) — updating ..."
    # Strip id/createdAt/updatedAt fields to avoid conflicts, then PUT
    local payload
    payload=$(jq 'del(.id, .createdAt, .updatedAt, .versionId)' "$file")
    RESPONSE=$(n8n_api -X PUT \
      -H "Content-Type: application/json" \
      -d "$payload" \
      "${N8N_BASE_URL}/api/v1/workflows/${existing_id}")
  else
    echo "  No existing workflow found — creating new ..."
    local payload
    payload=$(jq 'del(.id, .createdAt, .updatedAt, .versionId)' "$file")
    RESPONSE=$(n8n_api -X POST \
      -H "Content-Type: application/json" \
      -d "$payload" \
      "${N8N_BASE_URL}/api/v1/workflows")
  fi

  local new_id
  new_id=$(echo "$RESPONSE" | jq -r '.id // empty')

  if [[ -n "$new_id" ]]; then
    echo "  ✓ '$wf_name' imported successfully (id: $new_id)"
    echo "  → Open: ${N8N_BASE_URL}/workflow/${new_id}"
  else
    echo "  ✗ Import failed for '$wf_name'"
    echo "  Response: $RESPONSE"
    return 1
  fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
check_deps

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <path/to/workflow.json> [<another.json> ...]"
  echo ""
  echo "Examples:"
  echo "  $0 clients/example-client/workflows/lead-intake-test.json"
  echo "  $0 clients/*/workflows/*.json"
  exit 1
fi

echo "Connecting to n8n at $N8N_BASE_URL ..."
echo ""

ERRORS=0
for file in "$@"; do
  if ! import_workflow "$file"; then
    ERRORS=$((ERRORS + 1))
  fi
  echo ""
done

if [[ $ERRORS -gt 0 ]]; then
  echo "Completed with $ERRORS error(s). Check the output above."
  exit 1
else
  echo "All imports complete."
  echo ""
  echo "Next steps:"
  echo "  1. Open n8n and verify the imported workflows look correct"
  echo "  2. Connect any required credentials (see credentials-checklist.md)"
  echo "  3. Run a test execution with a payload from the payloads/ folder"
fi
