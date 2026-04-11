# Med Spa Lead Gen to Google Sheets and GoHighLevel

This client package implements a Google Maps lead generation system for med spas, stores and deduplicates the leads in Google Sheets, and syncs qualified businesses into GoHighLevel as contacts.

The package follows the repo's one-workflow-per-outcome convention:

- med-spa-queue-builder builds the Google search queue from cities and client-approved keywords.
- med-spa-maps-collector pulls pending searches, runs the Google Maps scraper, and logs raw businesses.
- med-spa-enrichment-qualifier extracts contact details from websites and promotes qualified leads.
- med-spa-ghl-sync upserts qualified leads into GoHighLevel and writes sync status back to Sheets.
- med-spa-retry-refresh finds stale or failed leads and prepares them for reprocessing.

## Workflow Files

```text
med-spa-ghl/
  README.md
  requirements.md
  credentials-checklist.md
  payloads/
    queue-builder-cities.json
    google-sheet-tab-schema.json
  workflows/
    med-spa-queue-builder.json
    med-spa-maps-collector.json
    med-spa-enrichment-qualifier.json
    med-spa-ghl-sync.json
    med-spa-retry-refresh.json
```

## Required Google Sheets Tabs

Create one spreadsheet and add these tabs before you run the workflows:

- Search Queue
- Raw Results
- Qualified Leads
- Lead Events
- Error Log
- GHL Sync Log
- Run Log

The expected headers are in payloads/google-sheet-tab-schema.json.

## Production State Model

Google Sheets remains the state store for this package. The workflows now use a single lifecycle contract across Sheets:

```text
NEW -> SCRAPED -> ENRICHED -> DONE
             -> FAILED_RETRYABLE -> retry after next_retry_at
             -> FAILED_TERMINAL after max_attempts
             -> DISQUALIFIED when enrichment proves the business is not a fit
```

Search jobs are tracked separately in `Search Queue` with `search_job_id`, `status`, `attempt_count`, `max_attempts`, `next_retry_at`, `lease_owner`, and `lease_until`. Leads are tracked by `lead_id` in `Raw Results` and `Qualified Leads`; `lead_id` is derived from normalized domain, Google place ID, phone, or business name plus city and state.

## Google Sheets Migration Notes

Before importing the hardened workflows, update the spreadsheet headers from `payloads/google-sheet-tab-schema.json`.

Add these tabs:

- Lead Events: immutable per-stage audit records.
- Error Log: retryable and terminal failure records.

Change these existing tabs:

- Search Queue: add `search_job_id`, retry fields, lease fields, Apify checkpoint fields, completion fields, and `schema_version`.
- Raw Results: add `lead_id`, identity fields, pipeline status, retry fields, lease fields, qualification fields, and error fields.
- Qualified Leads: add `lead_id`, identity fields, `pipeline_status`, `qualification_status`, retry fields, lease fields, error fields, `done_at`, and `schema_version`.
- GHL Sync Log: add `lead_id`.

Do not remove the legacy `queue_key`, `raw_result_key`, or `dedupe_key` columns yet. They are retained for compatibility, but the production matching columns are now `search_job_id` for search jobs and `lead_id` for leads.

## Recommended Build Order

1. Import med-spa-queue-builder.json and run it once to seed Search Queue.
2. Import and run med-spa-maps-collector.json to populate Raw Results.
3. Import and run med-spa-enrichment-qualifier.json to build Qualified Leads.
4. Skip med-spa-ghl-sync.json for now if you are testing Google Sheets only.
5. Activate med-spa-retry-refresh.json after the other workflows are working.

## External Services

- Google Sheets
- Apify Google Maps scraper actor
- GoHighLevel Contacts API (optional for later)

The workflows are exported without bound credentials so you can attach your own credentials in n8n after import.

## Notes

- Default seed mode uses a hardcoded multi-state metro seed built from the U.S. Census city population rankings: up to the top 5 cities per state where available, plus DC. Expect about 241 cities and roughly 2,410 search queue rows with the current 10-keyword set.
- The exact client keyword list is embedded in the queue builder and matches `requirements.md`.
- med spa near me is converted into a location-specific search at runtime.
- The hardcoded metro payload is generated from the official U.S. Census city population rankings and shipped directly with this package, which avoids runtime dependency failures during queue seeding.
- For GoHighLevel custom fields, add the field IDs to the configuration node inside med-spa-ghl-sync after import.
- Store Apify and GoHighLevel tokens in n8n credentials rather than workflow JSON before production activation.
