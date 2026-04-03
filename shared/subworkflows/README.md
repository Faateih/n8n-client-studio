# Shared Subworkflows

Exported n8n sub-workflow JSON files called by two or more client workflows.

## When to Add Here

Only promote a sub-workflow here when it is referenced by workflows for two or more clients. Until then, keep it in the client folder.

## File Naming

`<purpose>.json` — e.g., `normalize-contact.json`, `send-slack-alert.json`

## Note on Mounting

This folder is mounted read-only into the n8n container at `/home/node/subworkflows` (see `docker-compose.yml`). You can reference files from this path inside n8n if needed, though most sub-workflows are imported as regular n8n workflows and called via the Execute Workflow node.

## Usage

To use a sub-workflow:
1. Import the JSON into n8n via `./scripts/import-workflows.sh shared/subworkflows/<name>.json`
2. In the parent workflow, add an "Execute Workflow" node
3. Reference the sub-workflow by name
