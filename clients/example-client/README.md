# Example Client — Lead Intake Test

This folder contains the `lead-intake-test` workflow — a self-contained webhook workflow designed to verify your local n8n setup, MCP integration, export/import tooling, and debugging workflow.

**No external credentials are required.**

---

## What It Does

Accepts a JSON payload via webhook, validates required fields (`name` and `email`), normalizes the data, and returns a structured JSON response.

This is a test/verification workflow. Its purpose is to prove the full dev loop works before you build anything real.

---

## Workflow Details

| Field | Value |
|---|---|
| Name | `lead-intake-test` |
| Trigger | Webhook (POST) |
| Webhook path | `/webhook/lead-intake-test` |
| Credentials required | None |
| Export file | `workflows/lead-intake-test.json` |

---

## Node Structure

```
Webhook (POST /webhook/lead-intake-test)
  └── Validate Required Fields (Code)
        ├── [missing fields] → Return Error Response (Respond to Webhook)
        └── [valid] → Normalize Payload (Code)
                        └── Return Success Response (Respond to Webhook)
```

---

## Testing

Send either of the test payloads using curl, Postman, or n8n's built-in "Test Webhook" button.

### Happy Path

```bash
curl -X POST http://localhost:5678/webhook/lead-intake-test \
  -H "Content-Type: application/json" \
  -d @payloads/lead-intake-happy-path.json
```

Expected response:

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

### Missing Email

```bash
curl -X POST http://localhost:5678/webhook/lead-intake-test \
  -H "Content-Type: application/json" \
  -d @payloads/lead-intake-missing-email.json
```

Expected response:

```json
{
  "success": false,
  "error": "missing_required_fields",
  "fields": ["email"],
  "received_at": "2026-04-03T12:00:00.000Z"
}
```

---

## Credentials Checklist

None required. See `credentials-checklist.md` for the template used in real client workflows.

---

## Files

```
example-client/
  README.md                          ← this file
  requirements.md                    ← goal, inputs, outputs, test plan
  credentials-checklist.md           ← empty for this workflow (no credentials needed)
  workflows/
    lead-intake-test.json            ← exported workflow (import into n8n)
  payloads/
    lead-intake-happy-path.json      ← valid test payload
    lead-intake-missing-email.json   ← error test payload
  prompts/                           ← (empty — no AI prompts needed for this workflow)
```
