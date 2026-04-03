# MCP Usage Guide

n8n MCP is a **development and debugging tool**. Use it to move faster inside Cursor — not as a runtime component.

---

## What MCP Is For

| Use | OK? |
|---|---|
| List workflows and inspect their structure | ✅ |
| Trigger a test execution with a payload | ✅ |
| Read execution results and error details | ✅ |
| Ask the AI to explain a failure | ✅ |
| Make small, targeted edits to a workflow | ✅ with caution |
| Automate credential creation | ❌ |
| Deploy to production | ❌ |
| Run workflows in a loop unattended | ❌ |
| Replace manual testing in the n8n UI | ❌ |

---

## The Safe Dev Loop

```
1. PLAN
   Write what the workflow needs to do in .cursor/plans/<name>.md
   Keep it short: trigger → steps → output

2. BUILD
   Build the workflow in the n8n UI manually
   Use real nodes, not code nodes as a shortcut

3. TEST
   Send a test payload via the n8n UI "Test Workflow" button
   Use payloads from clients/<name>/payloads/

4. INSPECT WITH MCP
   If something fails, ask Cursor/MCP to:
   - Show the last execution result
   - Explain the error
   - Suggest a fix

5. EDIT
   Make fixes in the n8n UI (preferred) or via MCP for small changes
   Always re-test after any edit

6. EXPORT
   ./scripts/export-workflows.sh
   (or export manually from n8n UI → Download)

7. COMMIT
   git add clients/<name>/workflows/<workflow>.json
   git commit -m "feat(example-client): add lead-intake-test workflow"
```

---

## MCP Safety Rules

**1. One action at a time.**
Never chain MCP calls without checking the result of each one first.

**2. Always test after MCP edits.**
MCP can modify workflow JSON. Verify in the n8n UI that the workflow still looks right before committing.

**3. Do not use MCP to create credentials.**
Credentials contain secrets. Always create them in the n8n UI directly.

**4. Do not run production workflows via MCP.**
MCP is connected to your local instance only. Keep it that way.

**5. Export before making MCP edits.**
If MCP will modify a workflow, export the current JSON first so you have a rollback point.

```bash
./scripts/export-workflows.sh
git stash   # or commit the export first
# now make MCP edits
```

**6. Treat MCP suggestions as drafts.**
MCP may suggest workflow changes that look correct but miss business context. Always review before accepting.

---

## Connecting MCP to Cursor

Add to your Cursor MCP config (`~/.cursor/mcp.json` or via Cursor Settings → MCP):

```json
{
  "mcpServers": {
    "n8n": {
      "command": "npx",
      "args": ["-y", "n8n-mcp"],
      "env": {
        "N8N_HOST": "http://localhost:5678",
        "N8N_USERNAME": "admin",
        "N8N_PASSWORD": "changeme"
      }
    }
  }
}
```

Replace `changeme` with the password from your `.env` file. This config lives on your machine only — do not commit it to the repo.

---

## Useful MCP Prompts for Cursor

```
Show me the last 5 executions of the "lead-intake-test" workflow and 
summarize any errors.

The "lead-intake-test" workflow is failing at the validation step. 
Show me the execution data and suggest a fix.

List all workflows and tell me which ones have had errors in the 
last 24 hours.

I need to add a step to the "lead-intake-test" workflow that 
normalizes the email field to lowercase. Show me the current 
workflow structure first, then suggest the change.
```
