# Requirements - Med Spa Lead Gen

## Goal

Find med spas from Google Maps and Google Business Profiles across the US, enrich them with business contact details, write everything into Google Sheets, and automatically create qualified contacts in GoHighLevel.

## Locked Inputs

- Geography: US nationwide
- Source: Google Maps and Google Business Profiles
- CRM: GoHighLevel contact creation and update
- Control plane: Google Sheets
- Contact depth: business details plus general email and contact page
- Delivery: no opportunities in v1, contact plus tags only

## Search Vocabulary

The queue builder uses this exact client-approved search list:

- med spa
- medical spa
- cosmetic clinic
- aesthetic clinic
- botox clinic
- injectables
- dermal fillers
- laser hair removal
- skin rejuvenation
- med spa near me

## Dedupe Rules

Priority order:

1. normalized website domain
2. normalized phone
3. normalized business name + city + state

If one business is found by multiple keywords, append the keyword to matched_keywords rather than creating a duplicate row.

## Google Sheets Tabs

- Search Queue
- Raw Results
- Qualified Leads
- GHL Sync Log
- Run Log

## GoHighLevel Behavior

- Upsert qualified leads into a single location or sub-account
- Apply tags: source_google_maps, industry_med_spa, kw_*, city_*, state_*
- Write sync status back to Sheets
- Do not create opportunities in v1
