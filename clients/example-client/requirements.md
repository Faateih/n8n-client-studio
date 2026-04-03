# Requirements — lead-intake-test

## Goal

Provide a simple, credential-free workflow to verify the full local dev loop:

1. n8n is running and reachable
2. Webhook trigger works
3. Code nodes execute correctly
4. Execution history is saved and browsable
5. MCP can inspect and query executions
6. Export produces valid JSON
7. Import re-creates the workflow correctly
8. Git commit captures the export

This is a test scaffold. It mirrors the pattern used in real lead intake workflows.

---

## Trigger

- **Type:** Webhook
- **Method:** POST
- **Path:** `/webhook/lead-intake-test`
- **Authentication:** None (local dev only)

---

## Input

JSON body with the following fields:

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | string | ✅ | Contact's full name |
| `email` | string | ✅ | Contact's email address |
| `source` | string | ❌ | Where the lead came from (e.g., "website", "referral") |
| `message` | string | ❌ | Optional message from the lead |

---

## Processing Steps

1. **Validate Required Fields**
   - Check that `name` and `email` are present and non-empty
   - If either is missing → return error response immediately

2. **Normalize Payload**
   - Trim whitespace from `name` and `email`
   - Lowercase `email`
   - Default `source` to `"unknown"` if not provided
   - Default `message` to `""` if not provided

3. **Add Metadata**
   - `received_at`: ISO timestamp of when the webhook was received
   - `lead_status`: `"new"`
   - `workflow_version`: `"1.0.0"`

4. **Return Response**
   - On success: structured JSON with `success: true` and the normalized lead object
   - On error: structured JSON with `success: false`, error slug, and missing field names

---

## Output

### Success (HTTP 200)

```json
{
  "success": true,
  "lead": {
    "name": "Jane Smith",
    "email": "jane@example.com",
    "source": "website",
    "message": "Interested in your services.",
    "lead_status": "new",
    "received_at": "2026-04-03T12:00:00.000Z",
    "workflow_version": "1.0.0"
  }
}
```

### Validation Error (HTTP 400)

```json
{
  "success": false,
  "error": "missing_required_fields",
  "fields": ["email"],
  "received_at": "2026-04-03T12:00:00.000Z"
}
```

---

## Test Plan

| Test | Payload | Expected |
|---|---|---|
| Happy path | `lead-intake-happy-path.json` | HTTP 200, success response with normalized lead |
| Missing email | `lead-intake-missing-email.json` | HTTP 400, error response listing `email` |
| Missing both fields | `{ "source": "test" }` | HTTP 400, error response listing `name` and `email` |
| Extra fields | Add unknown fields to happy-path payload | Ignored, success response unchanged |

---

## Acceptance Criteria

- [ ] Both test payloads return the expected responses
- [ ] Execution history shows both successful and failed executions
- [ ] MCP can list and inspect the executions
- [ ] Workflow exports to `workflows/lead-intake-test.json`
- [ ] Import re-creates the workflow and it passes both tests again
