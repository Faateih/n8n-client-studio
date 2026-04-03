# Credentials Checklist — Example Client

## lead-intake-test workflow

This workflow requires **no external credentials**. It is a self-contained test workflow.

---

## Template: How to Use This Checklist

For real client workflows, this file lists every credential the workflow needs. The client fills it in and creates each credential in their n8n instance before activating the workflow.

---

### Credential Entry Template

```
## [Service Name] — [Credential Type in n8n]

**Purpose:** What this credential is used for in the workflow

**n8n Credential Name:** Exact name to use when creating it in n8n
  (the workflow nodes reference this name)

**How to get the value:**
  1. Log in to [service dashboard URL]
  2. Go to [Settings → API Keys] or equivalent
  3. Create a new key with the following scopes: [list scopes]
  4. Copy the key — you will only see it once

**Environment:** [ ] Sandbox / [ ] Production
  (Use sandbox for testing. Switch to production when going live.)

**Notes:**
  - Any special requirements, IP allowlisting, rate limits, etc.
```

---

## Example (filled in)

```
## OpenAI — OpenAI API

**Purpose:** Used by the "Summarize Message" node to generate a short summary

**n8n Credential Name:** OpenAI - Example Client
  (must match exactly — n8n is case-sensitive)

**How to get the value:**
  1. Log in to https://platform.openai.com
  2. Go to API Keys → Create new secret key
  3. Name it "n8n-example-client"
  4. Copy the key immediately (only shown once)

**Environment:** [x] Production

**Notes:**
  - Set a monthly spend limit in the OpenAI dashboard before going live
  - Use gpt-4o-mini for cost efficiency unless the client requires gpt-4o
```
