# Lumora Cloud — Source Data Model

## Purpose
This layer simulates the operational systems that feed the Revenue Intelligence Agent.

## Source ownership
- CRM: sales reps, accounts, contacts, deals, activities
- Marketing: campaigns, leads, attribution, MQL/SQL timestamps
- Billing: invoices, payments, outstanding balances
- Planning: sales and pipeline targets

## Revenue distinction
`raw_crm.deals.amount` represents sales booking / contract value.
Billing records represent invoiced and paid amounts. These metrics must remain separate.

## Raw-layer principle
The raw layer preserves source-system data. Strict cross-source foreign keys are intentionally avoided because records can arrive out of order and source systems may contain incomplete or low-quality records. Business validation and referential integrity are applied downstream.

## Data flow
CRM / Marketing / Billing / Planning
→ Raw PostgreSQL schemas
→ Transformation and Data Quality
→ Governed Reporting Layer
→ Revenue Intelligence Agent
→ Slack / Form / REST API / Power BI

## Security boundary
Raw operational tables are not directly exposed to natural-language reporting. The Revenue Intelligence Agent queries only the governed reporting layer through approved query templates and read-only reporting credentials.
