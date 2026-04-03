# Workflow Standards

Practical conventions that keep workflows readable, shippable, and easy to hand off.

---

## Naming

| Thing | Format | Example |
|---|---|---|
| Workflow name | `kebab-case`, verb-noun | `lead-intake`, `invoice-send`, `contact-sync` |
| Exported filename | same as workflow name + `.json` | `lead-intake-test.json` |
| Client folder | `kebab-case` company name | `acme-corp`, `example-client` |
| Webhook path | `/webhook/<workflow-name>` | `/webhook/lead-intake` |
| Node names | Title Case, action-focused | `Validate Fields`, `Normalize Payload`, `Return Response` |

---

## One Workflow = One Business Outcome

Each workflow should answer one question: *"What business thing does this do?"*

**Good:**
- `lead-intake` — receives a lead and stores it
- `invoice-send` — sends an invoice email when triggered
- `contact-sync` — syncs contacts from form to CRM

**Bad:**
- `main` — does everything
- `webhook-handler` — handles "all webhooks"
- `utilities` — a grab-bag of logic

If a workflow does two unrelated things, split it.

---

## Shared vs. Client-Specific

Move something to `shared/` only if it is used in **2 or more** client workflows.

```
shared/
  subworkflows/   ← sub-workflow JSON files called by multiple workflows
  payloads/       ← test payloads reused across clients
  prompts/        ← AI prompt fragments used in multiple workflows
```

When in doubt, keep it in the client folder. You can always promote it to shared later.

---

## Workflow Structure (Node Order)

Build workflows top-to-bottom in this order when applicable:

```
Trigger
  → Validate Input
  → Transform / Normalize
  → Business Logic
  → External Call (if needed)
  → Format Response / Output
```

Keep each node focused on one thing. Avoid packing multiple transformations into a single Code node.

---

## Error Handling

- Always add an error path on any node that can fail (HTTP, external API).
- Return structured error responses from webhooks — never expose raw n8n error messages.
- Use a consistent error shape:

```json
{
  "success": false,
  "error": "missing_required_fields",
  "fields": ["email"],
  "received_at": "2026-04-03T12:00:00Z"
}
```

---

## Code Nodes

Use Code nodes sparingly. Prefer built-in nodes.

When you do use a Code node:
- Keep it under ~30 lines
- Name it clearly: `Normalize Email`, not `Code`
- Add a sticky note explaining what it does and why

---

## Versioning

Each workflow JSON export is the source of truth for that workflow's version.

- Export after every meaningful change
- Commit with a clear message:
  ```
  feat(example-client): add email normalization to lead-intake
  fix(example-client): handle missing source field gracefully
  ```
- Add `workflow_version` to your workflow's output metadata so you can trace which version ran during a given execution

---

## Test Payloads

Every workflow needs at least two payloads in `clients/<name>/payloads/`:

1. `<workflow-name>-happy-path.json` — valid input, should succeed
2. `<workflow-name>-missing-<field>.json` — invalid input, should return structured error

Test both before exporting and committing.
