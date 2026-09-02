# Architecture

## End-to-End Flow
```text
CRM / Marketing / Billing / Planning
              ↓
       LUMORA | Source RO
              ↓
      n8n incremental sync
              ↓
      PostgreSQL raw layer
              ↓
fixed transactional reporting refresh
              ↓
        reporting schema
         ↙           ↘
 Governed REVINT    Power BI
 Slack/Form/API     Dashboards
```

## Incremental Cursor
Every entity uses `(source_updated_at, primary_key)`. The primary key is the deterministic tie-breaker when timestamps are equal.

## Worker Pattern
`LUMORA-SYNC-02 | Entity Sync Worker | Production Callable` accepts only approved `entity_key` values. Table identifiers remain hardcoded inside fixed extraction/upsert branches.

## Parent Orchestration
`LUMORA-SYNC-03 | Full Multi-Entity Sync Orchestrator` processes the fixed set of 10 approved entities and refreshes reporting once after the batch succeeds.

## Manager Reporting
Manager Request → Normalize → Context/Audit → AI Intent Parser → KPI Catalogue → Governance → Approved Query → Safe Parameters → Reporting RO → Result Validation → Analysis → Presentation → Audit Success.
