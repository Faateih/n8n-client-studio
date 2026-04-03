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

**1.** Create an API key in n8n: **Settings → API** (same key you can put in `N8N_API_KEY` in `.env` for import/export scripts).

**2.** In Cursor: **Settings → MCP** (or **Cursor Settings → Features → MCP**), add a server, **or** edit `~/.cursor/mcp.json` manually.

**3.** Use the official **[n8n-mcp](https://www.npmjs.com/package/n8n-mcp)** package (see its README for the latest env names). A typical **local** setup with **n8n management tools** (workflows, executions, etc.) looks like:

```json
{
  "mcpServers": {
    "n8n-mcp": {
      "command": "npx",
      "args": ["n8n-mcp"],
      "env": {
        "MCP_MODE": "stdio",
        "LOG_LEVEL": "error",
        "DISABLE_CONSOLE_OUTPUT": "true",
        "N8N_API_URL": "http://localhost:5678",
        "N8N_API_KEY": "paste-your-n8n-api-key-here"
      }
    }
  }
}
```

- **`MCP_MODE`: `stdio`** — required for desktop-style MCP clients so logs do not break the protocol (per n8n-mcp docs).
- **`N8N_API_URL`** — base URL of your n8n instance (no path to `/api/v1` unless the package docs say otherwise).
- **`N8N_API_KEY`** — same value as in your `.env`; n8n’s API uses **`X-N8N-API-KEY`**, which this server sends for you.

**4.** Restart Cursor (or reload MCP) after saving.

Keep this file **only on your machine** — do not commit API keys to git.

If tools only show **node documentation** and not your instance, check that **`N8N_API_URL`** and **`N8N_API_KEY`** are set and that the key is valid. For package-specific options, see [n8n-mcp on GitHub](https://github.com/czlonkowski/n8n-mcp).

### Troubleshooting: `spawn npx ENOENT`

Cursor launches MCP with a minimal environment; it may not find **`npx`** on `PATH` (common with **nvm** / **fnm**). Run `which npx` in a terminal and set the MCP **`command`** to that **full path** (e.g. `/opt/homebrew/bin/npx`), not the bare word `npx`. Reload the window after editing `~/.cursor/mcp.json`.

### Troubleshooting: `env: node: No such file or directory`

`npx` was found (full path works) but **`node` is not on `PATH`** when Cursor spawns the process. Add **`PATH`** to the MCP server’s **`env`** so it includes Homebrew’s bin directory, for example:

`"PATH": "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/bin:/bin:/usr/sbin:/sbin"`

(Adjust if Node is installed elsewhere.) Then reload the window.

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
