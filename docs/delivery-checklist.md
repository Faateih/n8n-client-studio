# Client Workflow Delivery Checklist

Use this before handing off any workflow to a client. Copy it into the client's folder and check off each item.

---

## Pre-Delivery Checklist

### Workflow Quality

- [ ] Workflow has a clear, single business purpose
- [ ] Workflow name follows naming conventions (`kebab-case`, verb-noun)
- [ ] All nodes are named descriptively (no "Node", "Code", "IF1")
- [ ] Error paths exist on all external calls
- [ ] Error responses use the standard structured shape
- [ ] No hardcoded credentials, API keys, or secrets anywhere in the workflow
- [ ] Workflow outputs `workflow_version` in response metadata
- [ ] Sticky notes explain any non-obvious logic

### Testing

- [ ] Happy-path test payload passes end to end
- [ ] Missing-field payload returns the correct structured error
- [ ] Tested with real (or realistic) data at least once
- [ ] Execution history reviewed — no unexpected errors
- [ ] Webhook URL tested from outside n8n (curl or Postman)

### Documentation

- [ ] `clients/<name>/README.md` is accurate and up to date
- [ ] `clients/<name>/requirements.md` reflects the final behavior
- [ ] `clients/<name>/credentials-checklist.md` lists every credential needed
- [ ] Test payloads exist and are committed

### Export and Version Control

- [ ] Workflow exported and saved to `clients/<name>/workflows/<name>.json`
- [ ] Export is committed to git with a meaningful commit message
- [ ] Git history is clean (no stray test commits, no `.env` files)

---

## Handoff Package

When delivering to a client, send them:

1. **Workflow JSON** — they import this into their own n8n instance
2. **Credentials Checklist** — `credentials-checklist.md` from their client folder
3. **Test Payloads** — so they can verify the import worked
4. **README** — the client folder README explaining what the workflow does

---

## Client Import Instructions (for the client)

Give the client these steps:

```
1. Open your n8n instance
2. Go to Workflows → Import From File
3. Upload the .json file you received
4. Go to Settings → Credentials → New Credential
5. Create each credential listed in credentials-checklist.md
6. Open the imported workflow and connect credentials to the appropriate nodes
7. Activate the workflow
8. Send the happy-path test payload to confirm it's working
```

---

## Post-Delivery

- [ ] Client confirmed the workflow is working in their environment
- [ ] Any issues found post-delivery are tracked and fixed
- [ ] Final fixed version re-exported and committed
- [ ] Client folder archived or tagged in git if project is complete
