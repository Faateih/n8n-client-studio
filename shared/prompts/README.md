# Shared Prompts

AI prompt fragments reused across two or more client workflows.

## When to Add Here

Only move a prompt here when it is actively used in two or more client workflows. Otherwise keep it in `clients/<name>/prompts/`.

## File Naming

`<purpose>-prompt.txt` — e.g., `lead-summary-prompt.txt`, `email-draft-prompt.txt`

## Usage

Reference the prompt content in a workflow's AI node by reading this file or pasting the content directly into the node. Document which clients/workflows use each prompt in a comment at the top of the file.
