# Credentials Checklist - Med Spa GHL

## Google Sheets - Google Sheets OAuth2 API

Purpose: Read and write the Search Queue, Raw Results, Qualified Leads, GHL Sync Log, and Run Log tabs.

n8n Credential Name: Google Sheets - Med Spa Lead Gen

Setup:
1. Open n8n -> Credentials -> New
2. Choose Google Sheets OAuth2 API
3. Connect the Google account that owns the spreadsheet
4. Grant Sheets access

Notes:
- Use one spreadsheet for all tabs in v1.
- Attach this credential to every Google Sheets node after import.

## Apify - HTTP Header Auth

Purpose: Run the Google Maps scraper actor from the med-spa-maps-collector workflow.

n8n Credential Name: Apify - Med Spa Lead Gen

Setup:
1. Log in to https://console.apify.com/
2. Go to Settings -> Integrations / API
3. Copy your API token
4. Create an n8n HTTP header credential or paste the token into the configuration node after import

Notes:
- The workflow is configured for a free-tier-friendly actor pattern.
- Start with conservative limits to stay within free credits.

## GoHighLevel - HTTP Header Auth

Purpose: Upsert qualified businesses into the client GoHighLevel location using the Contacts API. This is optional while you are testing Google Sheets only.

n8n Credential Name: GoHighLevel - Med Spa Lead Gen

Setup:
1. In the target GoHighLevel sub-account, create a Private Integration Token or Sub-Account token
2. Copy the bearer token
3. In n8n, create an HTTP header auth credential or keep the token in the workflow configuration node while testing

Required headers:
- Authorization: Bearer <token>
- Version: 2021-07-28

Optional GoHighLevel custom fields:
- google_maps_url
- matched_keywords
- dedupe_key
