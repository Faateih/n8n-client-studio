# n8n Client Studio

A minimal local workspace for building, testing, debugging, and versioning client workflows using n8n + Docker + SQLite + Cursor + Git.

---

## Quick Start

```bash
# 1. Clone and enter the repo
git clone <your-repo-url> n8n-client-studio
cd n8n-client-studio

# 2. Set up environment
cp .env.example .env
# Edit .env — change N8N_BASIC_AUTH_PASSWORD at minimum

# 3. Start n8n
docker compose up -d

# 4. Open the UI
open http://localhost:5678
```

Login with the user/password from your `.env` file (default: `admin` / `changeme`).

After first login, add **`N8N_API_KEY`** to the same `.env` file (n8n → **Settings → API** → create key). Import/export scripts and the API require `X-N8N-API-KEY`; basic auth alone is not enough. See `docs/setup.md`.

---

## Folder Layout

```
n8n-client-studio/
├── .env.example          ← local runtime config template (safe to commit)
├── docker-compose.yml    ← n8n + SQLite, single container
├── README.md
├── .gitignore
├── .cursor/
│   ├── plans/            ← scratch space for workflow design notes
│   └── rules/            ← Cursor AI rules for this repo
├── docs/
│   ├── setup.md          ← full setup guide + credential policy
│   ├── workflow-standards.md
│   ├── mcp-usage.md
│   └── delivery-checklist.md
├── shared/
│   ├── prompts/          ← reusable AI prompt fragments
│   ├── payloads/         ← reusable test payloads
│   └── subworkflows/     ← shared sub-workflow JSON exports
├── clients/
│   └── example-client/   ← one folder per client
└── scripts/
    ├── export-workflows.sh
    └── import-workflows.sh
```

---

## Dev Loop

```
plan → build in n8n → test with payload → inspect with MCP → export JSON → commit
```

See `docs/mcp-usage.md` for the full safe MCP dev loop.

---

## Key Decisions

| Decision | Reason |
|---|---|
| SQLite only | Zero config, sufficient for local dev |
| No Redis / queue mode | Not needed until you have high-volume prod traffic |
| Credentials stay in n8n UI | Keeps secrets out of git entirely |
| One workflow = one business outcome | Easy to hand off, test, and version |

---

## Useful Commands

```bash
# Stop n8n
docker compose down

# View logs
docker compose logs -f n8n

# Restart after config change
docker compose down && docker compose up -d

# Export / import (require N8N_API_KEY in .env — see docs/setup.md)
./scripts/export-workflows.sh
./scripts/import-workflows.sh clients/example-client/workflows/lead-intake-test.json
```

---

## First Workflow

See `clients/example-client/` for the `lead-intake-test` workflow — a self-contained webhook workflow that needs no external credentials, designed to verify your local setup end to end.

Full docs: `clients/example-client/README.md`
