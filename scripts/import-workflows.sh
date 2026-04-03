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
#   - N8N_API_KEY in .env (Settings → API in n8n)

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$ROOT_DIR/.env"
ENV_PARENT="$ROOT_DIR/../.env"

# Parent .env first (e.g. Documents/n8n/.env), then repo .env overrides
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
    echo "The n8n REST API requires header X-N8N-API-KEY (basic auth alone is not enough)."
    echo "  1. Open n8n → Settings → API"
    echo "  2. Create an API key"
    echo "  3. Add a line:  N8N_API_KEY=your-key  to either:"
    echo "       ${ENV_PARENT}   (parent folder, loaded first)"
    echo "       ${ENV_FILE}     (repo root, overrides parent)"
    exit 1
  fi
}

# n8n API calls — API key required (see docs/setup.md)
n8n_api() {
  curl -s \
    -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
    -H "Accept: application/json" \
    "$@"
}

# Strip fields the REST API rejects on POST/PUT (read-only or server-managed).
# Examples: active, meta, tags (assign tags in the UI after import)
sanitize_workflow_for_api() {
  jq '
    del(
      .id,
      .createdAt,
      .updatedAt,
      .versionId,
      .versionCounter,
      .active,
      .meta,
      .shared,
      .tags
    )
  ' "$1"
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
  local list_resp existing_id
  list_resp=$(n8n_api "${N8N_BASE_URL}/api/v1/workflows?limit=100")
  if ! echo "$list_resp" | jq -e '.data | type == "array"' &>/dev/null; then
    echo "  ✗ API error while listing workflows:"
    echo "$list_resp" | jq . 2>/dev/null || echo "$list_resp"
    return 1
  fi
  existing_id=$(echo "$list_resp" | jq -r --arg name "$wf_name" '
    (.data // [])[]? | select(.name == $name) | .id
  ' | head -1)

  if [[ -n "$existing_id" ]]; then
    echo "  Found existing workflow (id: $existing_id) — updating ..."
    local payload
    payload=$(sanitize_workflow_for_api "$file")
    RESPONSE=$(n8n_api -X PUT \
      -H "Content-Type: application/json" \
      -d "$payload" \
      "${N8N_BASE_URL}/api/v1/workflows/${existing_id}")
  else
    echo "  No existing workflow found — creating new ..."
    local payload
    payload=$(sanitize_workflow_for_api "$file")
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
    echo "  → Activate in the UI if you need the webhook (API import does not set active)"
  else
    echo "  ✗ Import failed for '$wf_name'"
    echo "  Response: $RESPONSE"
    return 1
  fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
check_deps
require_api_key

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
  echo "  2. Toggle Active ON if you need the production webhook URL"
  echo "  3. Connect any required credentials (see credentials-checklist.md)"
  echo "  4. Run a test execution with a payload from the payloads/ folder"
fi
