# Setup Guide

## Prerequisites

- Docker Desktop (v4.x+)
- Docker Compose v2 (`docker compose` not `docker-compose`)
- Git
- Cursor IDE
- n8n MCP (optional — for dev/debug assistance in Cursor)

---

## 1. Local Startup

```bash
# Clone
git clone <your-repo-url> n8n-client-studio
cd n8n-client-studio

# Configure
cp .env.example .env
nano .env   # change N8N_BASIC_AUTH_PASSWORD at minimum

# Start
docker compose up -d

# Verify
docker compose logs -f n8n
# Look for: "Editor is now accessible via: http://localhost:5678"

# Open
open http://localhost:5678
```

n8n runs as a single container. Data is stored in a Docker-managed named volume (`n8n_data`), using SQLite. Nothing is written to your host filesystem outside of Docker.

### API key (for import/export scripts and MCP)

The n8n REST API (`/api/v1/...`) requires the **`X-N8N-API-KEY`** header. **Basic auth only protects the web UI** — it does not satisfy API requests.

1. Open n8n → **Settings** → **API** (wording may vary slightly by n8n version).
2. Create an API key and copy it (you may only see it once).
3. Add it to **`n8n-client-studio/.env`** — the file in the **same directory as `docker-compose.yml`**:

   ```bash
   N8N_API_KEY=paste-your-key-here
   ```

   The import/export scripts load **`../.env` first** (e.g. `Documents/n8n/.env`), then **`n8n-client-studio/.env`**, so repo values override the parent. You can keep `N8N_API_KEY` in either file.

4. Run scripts from the repo root: `cd n8n-client-studio && ./scripts/import-workflows.sh ...`

Do not commit `.env`. This key is for **your local n8n instance**, not third-party services.

---

## 2. Stopping and Restarting

```bash
docker compose down          # stop (data is preserved in volume)
docker compose down -v       # ⚠️  stop AND delete all data — fresh start
docker compose up -d         # start again
docker compose logs -f n8n   # follow logs
```

---

## 3. Where MCP Fits In

n8n MCP is a **development and debugging tool**, not part of the runtime.

You connect MCP to Cursor so the AI assistant can:

- List and inspect your workflows
- Run test executions and read results
- Help you understand execution failures
- Suggest edits to workflow JSON

MCP talks directly to your local n8n instance via the n8n API. It does **not** deploy workflows, manage credentials, or touch production.

To configure MCP in Cursor:
1. Install the `n8n-mcp` package or use the community MCP server
2. Point it at `http://localhost:5678` with your basic auth credentials
3. Add it to Cursor's MCP config (`.cursor/mcp.json` or Cursor settings)

See `docs/mcp-usage.md` for the safe usage rules.

---

## 4. Credential Policy

### What goes in `.env`

Only settings that configure the **local n8n container itself**:

- Network host, port, protocol
- Basic auth user/password for the UI
- Timezone
- Webhook base URL

`.env` is **not committed to git**. `.env.example` is — it contains no real values.

### What goes in the n8n Credentials UI

Everything a workflow needs to call an external service:

- API keys (OpenAI, Slack, HubSpot, etc.)
- OAuth tokens
- Webhook secrets
- Database connection strings
- SMTP credentials

**Why this separation?**

Credentials stored in the n8n UI are:
- Encrypted at rest in the SQLite database
- Never written to any file that git can see
- Scoped to specific workflows (optional)
- Easy to hand off: you give the client a credentials checklist, they enter values themselves

Credentials in `.env` or workflow JSON would end up in git history and would be visible to anyone who clones the repo.

### Setting up credentials

1. Open n8n → Settings → Credentials → New Credential
2. Choose the type (e.g., "OpenAI API")
3. Enter the value
4. Reference the credential by name inside your workflow node

Each client folder includes a `credentials-checklist.md` that lists what credentials the client's workflows need.

---

## 5. Persisting Data Across Rebuilds

The `n8n_data` volume persists your workflows, credentials, and execution history across `docker compose down / up` cycles.

If you want to back up everything:

```bash
# Export all workflow JSONs first
./scripts/export-workflows.sh

# Optionally back up the raw SQLite file
docker run --rm -v n8n_data:/data -v $(pwd):/backup alpine \
  cp /data/database.sqlite /backup/database.sqlite.bak
```

The workflow JSON exports in `clients/*/workflows/` are your primary backup. Commit them to git after every meaningful change.
