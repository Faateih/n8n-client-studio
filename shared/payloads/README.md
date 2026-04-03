# Shared Payloads

Test payloads reused across two or more client workflows.

## When to Add Here

Only move a payload here when the same test data is genuinely reused across multiple workflows or clients. Client-specific payloads stay in `clients/<name>/payloads/`.

## File Naming

`<workflow-type>-<scenario>.json` — e.g., `webhook-happy-path.json`, `generic-lead.json`
