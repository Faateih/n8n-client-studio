# Med Spa Lead Gen Setup

This guide is written for a fresh client setup from scratch.

It covers:

- Google Sheets setup
- n8n credential setup
- Apify token setup
- HighLevel token and location setup
- workflow import and configuration
- testing before go-live

## Recommended Budget

Recommended stack for about `$50/month`:

- `n8n`: self-hosted Community Edition = `$0`
- `Apify`: `Starter` plan = `$29/month`
- `HighLevel`: use the client's existing account/sub-account

Why this is the best fit:

- n8n does not need a paid cloud plan if you are self-hosting
- Apify free credits are usually too small for recurring lead generation
- the current workflow schedule is already tuned to stay under `10,000` monthly n8n executions

Official pricing:

- [n8n pricing](https://n8n.io/pricing/)
- [Apify pricing](https://apify.com/pricing)

## What The Client Needs

Before starting, make sure the client has:

- a Google account that can access the spreadsheet
- an Apify account
- a HighLevel account with the target sub-account/location
- an n8n instance running and accessible

## Files In This Package

- [README.md](/Users/faateih/Documents/n8n/n8n-client-studio/clients/med-spa-ghl/README.md)
- [requirements.md](/Users/faateih/Documents/n8n/n8n-client-studio/clients/med-spa-ghl/requirements.md)
- [credentials-checklist.md](/Users/faateih/Documents/n8n/n8n-client-studio/clients/med-spa-ghl/credentials-checklist.md)
- [payloads/google-sheet-tab-schema.json](/Users/faateih/Documents/n8n/n8n-client-studio/clients/med-spa-ghl/payloads/google-sheet-tab-schema.json)
- [scripts/setup-google-sheet-schema.gs](/Users/faateih/Documents/n8n/n8n-client-studio/clients/med-spa-ghl/scripts/setup-google-sheet-schema.gs)

## Step 1: Create The Google Sheet

Create one spreadsheet for the whole system.

Required tabs:

- `Search Queue`
- `Raw Results`
- `Qualified Leads`
- `Lead Events`
- `Error Log`
- `GHL Sync Log`
- `Run Log`

### Fastest way

Use the Apps Script helper:

1. Open the new Google Sheet.
2. Go to `Extensions > Apps Script`.
3. Paste the contents of [setup-google-sheet-schema.gs](/Users/faateih/Documents/n8n/n8n-client-studio/clients/med-spa-ghl/scripts/setup-google-sheet-schema.gs).
4. Run `setupMedSpaLeadGenSchema()`.
5. Approve Google permissions when prompted.

This creates the tabs and the header row structure to match the workflows.

### How to find the Google Sheet ID

Open the sheet in your browser.

The ID is the long string in the URL between:

`/spreadsheets/d/` and `/edit`

Example:

```text
https://docs.google.com/spreadsheets/d/1ABCDEF1234567890/edit#gid=0
```

The sheet ID is:

```text
1ABCDEF1234567890
```

## Step 2: Create The Google Sheets Credential In n8n

Official n8n docs:

- [Google credentials](https://docs.n8n.io/integrations/builtin/credentials/google/)
- [Google OAuth2 single service](https://docs.n8n.io/integrations/builtin/credentials/google/oauth-single-service/)

In n8n:

1. Go to `Credentials`
2. Create a `Google Sheets OAuth2 API` credential
3. Sign in with the Google account that can access the spreadsheet
4. Save it with a clear name, for example:
   `Google Sheets - Med Spa Lead Gen`

Important:

- after import, re-select this credential in Google Sheets nodes if n8n shows an empty binding
- imported workflows can carry blank credential IDs until you save them again in the UI

## Step 3: Create The Apify Credential In n8n

Official Apify docs:

- [Apify API getting started](https://docs.apify.com/api/v2/getting-started)
- [Apify integrations and API tokens](https://docs.apify.com/platform/integrations/api/)

### How to find the Apify token

In Apify Console:

1. Go to `Settings > Integrations`
2. Create or copy an API token
3. Keep it private

Apify documents that the token can be used in the `Authorization` header or as a `token` query parameter. This workflow uses the query-auth method in n8n.

### Create the credential in n8n

In n8n:

1. Go to `Credentials`
2. Create a `Query Auth` credential
3. Set:
   - `Name`: `token`
   - `Value`: `YOUR_APIFY_TOKEN`
4. Save it with a clear name, for example:
   `Apify Query Token`

## Step 4: Create The HighLevel Credential In n8n

Official HighLevel docs:

- [Private Integrations](https://marketplace.gohighlevel.com/docs/Authorization/PrivateIntegrationsToken/index.html)
- [Authorization overview](https://marketplace.gohighlevel.com/docs/Authorization/authorization_doc)
- [How to find Location ID](https://help.gohighlevel.com/support/solutions/articles/48001204848-how-do-i-find-my-client-s-location-id-)

### How to find or create the HighLevel token

Use a `Private Integration Token (PIT)`.

In HighLevel:

1. Go to `Settings > Private Integrations`
2. Create a new private integration
3. Give it a name like `n8n Med Spa Sync`
4. Select the scopes needed for contact sync
5. Copy the token immediately

Important:

- HighLevel says the token is only shown when created or rotated
- rotate it if it is ever exposed
- use a token for the same account/location you plan to sync into

### How to find the HighLevel Location ID

Option 1:

1. Open the client sub-account
2. Go to `Settings > Business Profile`
3. Copy the `Location ID`

Option 2:

Look in the browser URL for the value after `/location/` or in `locationId=...`

### Create the credential in n8n

In n8n:

1. Go to `Credentials`
2. Create a `Header Auth` credential
3. Set:
   - `Name`: `Authorization`
   - `Value`: `Bearer YOUR_GHL_TOKEN`
4. Save it with a clear name, for example:
   `GHL Token`

Important:

- the header name must be exactly `Authorization`
- the value must start with `Bearer `
- if you use the wrong token or wrong account, HighLevel will return `401 Invalid JWT`

## Step 5: Import The Workflows

Import these workflow files:

- [med-spa-queue-builder.json](/Users/faateih/Documents/n8n/n8n-client-studio/clients/med-spa-ghl/workflows/med-spa-queue-builder.json)
- [med-spa-maps-collector.json](/Users/faateih/Documents/n8n/n8n-client-studio/clients/med-spa-ghl/workflows/med-spa-maps-collector.json)
- [med-spa-enrichment-qualifier.json](/Users/faateih/Documents/n8n/n8n-client-studio/clients/med-spa-ghl/workflows/med-spa-enrichment-qualifier.json)
- [med-spa-ghl-sync.json](/Users/faateih/Documents/n8n/n8n-client-studio/clients/med-spa-ghl/workflows/med-spa-ghl-sync.json)
- [med-spa-retry-refresh.json](/Users/faateih/Documents/n8n/n8n-client-studio/clients/med-spa-ghl/workflows/med-spa-retry-refresh.json)

If using the helper script:

```bash
cd /Users/faateih/Documents/n8n/n8n-client-studio
./scripts/import-workflows.sh clients/med-spa-ghl/workflows/*.json
```

## Step 6: Fill Workflow Configuration In n8n

Each workflow has a `Workflow Configuration` node.

Set the following values:

### `med-spa-queue-builder`

- `spreadsheetId`: client Google Sheet ID

### `med-spa-maps-collector`

- `spreadsheetId`: client Google Sheet ID

Leave these as shipped unless you intentionally want to change them:

- `apifyActorId`: `compass~crawler-google-places`
- `countryCode`: `us`
- `language`: `en`
- `maxQueriesPerRun`: `20`
- `maxCrawledPlacesPerSearch`: `40`

### `med-spa-enrichment-qualifier`

- `spreadsheetId`: client Google Sheet ID

### `med-spa-ghl-sync`

- `spreadsheetId`: client Google Sheet ID
- `ghlLocationId`: client HighLevel location ID

Optional custom fields:

- `googleMapsFieldId`
- `matchedKeywordsFieldId`
- `dedupeKeyFieldId`

Leave blank unless the client already has matching custom fields in HighLevel.

### `med-spa-retry-refresh`

- `spreadsheetId`: client Google Sheet ID

## Step 7: Re-select Credentials In Nodes

This is important.

Because imported n8n workflows may contain blank credential IDs, open the relevant nodes and re-select the saved credentials.

### Google Sheets nodes

Select:

- `Google Sheets - Med Spa Lead Gen`

### Apify node

Workflow: `med-spa-maps-collector`  
Node: `Run Google Maps Scraper`

Select:

- `Authentication`: `Generic Credential Type`
- `Generic Auth Type`: `Query Auth`
- Credential: `Apify Query Token`

### HighLevel node

Workflow: `med-spa-ghl-sync`  
Node: `Upsert Contact in GHL`

Select:

- `Authentication`: `Generic Credential Type`
- `Generic Auth Type`: `Header Auth`
- Credential: `GHL Token`

Then save the workflow.

## Step 8: Run The Setup Test In Order

Do this in order:

1. Run `med-spa-queue-builder` once
2. Confirm rows appear in `Search Queue`
3. Run `med-spa-maps-collector`
4. Confirm rows appear in `Raw Results`
5. Run `med-spa-enrichment-qualifier`
6. Confirm rows appear in `Qualified Leads`
7. Run `med-spa-ghl-sync`
8. Confirm contacts appear in HighLevel and rows update in `Qualified Leads`
9. Run `med-spa-retry-refresh`
10. Confirm retry rows appear in `Search Queue` when applicable

## Step 9: Turn On Schedules

Current production schedules are:

- `med-spa-maps-collector`: every 15 minutes at `:00`
- `med-spa-enrichment-qualifier`: every 15 minutes at `:15`
- `med-spa-ghl-sync`: every 15 minutes at `:30`
- `med-spa-retry-refresh`: hourly at `:45`

This stays under the target of `10,000` monthly n8n executions, excluding the queue builder.

## What Counts As Qualified

A lead is currently qualified if it matches med-spa intent in at least one of these:

- Google category
- website content
- source keyword

Examples of match terms:

- `med spa`
- `medical spa`
- `aesthetic`
- `cosmetic`
- `injectable`
- `dermal`
- `laser`
- `skin rejuvenation`
- `botox`

## Recommended Demo Checklist

For your client demo, test these exact things:

1. Fresh spreadsheet setup from Apps Script
2. Fresh Google Sheets credential connection
3. Fresh Apify credential connection
4. Fresh HighLevel credential connection
5. Queue builder run
6. One maps collection run
7. One enrichment run
8. One GHL sync run
9. One failed credential scenario and recovery

## Common Setup Mistakes

### Google Sheet not found

Cause:

- `spreadsheetId` still set to `REPLACE_WITH_GOOGLE_SHEET_ID`

Fix:

- update the `Workflow Configuration` node in every workflow

### GHL returns `Invalid JWT`

Cause:

- wrong token
- wrong account/location
- token value missing `Bearer `

Fix:

- recreate the PIT
- use the correct client location
- set Header Auth as:
  - `Name`: `Authorization`
  - `Value`: `Bearer YOUR_GHL_TOKEN`

### Apify token not provided

Cause:

- wrong n8n credential type
- query auth not selected

Fix:

- create `Query Auth`
  - `Name`: `token`
  - `Value`: `YOUR_APIFY_TOKEN`

### Credential selected but n8n still errors

Cause:

- imported workflow has blank credential ID

Fix:

- re-select the credential in the node
- save the workflow
- reopen and run again

## Go-Live Checklist

- Google Sheet created with correct tabs and headers
- real `spreadsheetId` entered in all workflows
- Google Sheets credential connected
- Apify credential connected
- HighLevel credential connected
- `ghlLocationId` entered
- manual test run succeeds for each workflow
- schedules activated
- first live run monitored in:
  - `Qualified Leads`
  - `GHL Sync Log`
  - `Lead Events`
  - `Error Log`

## Security Notes

- never put tokens into workflow JSON
- keep Apify and HighLevel tokens in n8n credentials only
- rotate tokens if they were ever shared in chat, screenshots, or commits
- HighLevel recommends rotating private integration tokens regularly
